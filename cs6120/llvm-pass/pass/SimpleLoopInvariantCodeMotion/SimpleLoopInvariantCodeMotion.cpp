#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/PriorityWorklist.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/raw_ostream.h"
#include <sys/types.h>

using namespace llvm;

namespace {

constexpr char PassName[] = "slicm";
constexpr char PluginName[] = "Simple Loop Invariant Code Motion";

class SimpleLoopInvariantCodeMotionImpl {
public:
  SimpleLoopInvariantCodeMotionImpl(LoopInfo &LI, DominatorTree &DT)
      : LI(LI), DT(DT) {}

  /// Run the loop invariant code motion on the loop \p L. Subloops are
  /// expected to be already processed.
  bool run(Loop &L) const;

  /// Check if the loop \p L is in the candidate form.
  bool isCandidate(Loop &L) const;

  /// Check if the instruction \p I is safe to hoist with respect to the loop \p
  /// L.
  bool isSafeToHoist(Instruction &I, Loop &L) const;

  /// Check if the instruction \p I dominates all blocks in \p Blocks.
  bool dominatesAll(Instruction &I, ArrayRef<BasicBlock *> Blocks) const;

  /// \param I The instruction to check, which is expected to be in a loop.
  /// \param LIs The current set of loop invariant instructions.
  bool
  hasLoopInvariantOperands(Instruction &I,
                           const SmallPtrSetImpl<Instruction *> &LIs) const;

private:
  LoopInfo &LI;
  DominatorTree &DT;
};

/// Append the loop \p L and its nested loops to the worklist \p Worklist.
/// \note The innermost loop will be the first element when popping from the
/// worklist with `pop_back_val`.
void appendNestedLoopsToWorklist(Loop &L,
                                 SmallPriorityWorklist<Loop *, 4> &Worklist) {
  Worklist.insert(&L);
  for (auto &SubLoop : L) {
    appendNestedLoopsToWorklist(*SubLoop, Worklist);
  }
}

class SimpleLoopInvariantCodeMotionPass
    : public PassInfoMixin<SimpleLoopInvariantCodeMotionPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &FAM) {
    errs() << "SLICM @ " << F.getName() << "\n";
    auto &LI = FAM.getResult<LoopAnalysis>(F);
    auto &DT = FAM.getResult<DominatorTreeAnalysis>(F);
    SimpleLoopInvariantCodeMotionImpl Impl(LI, DT);

    bool Changed = false;
    // XXX: Is the order of the top-level loops important?
    for (auto *L : LI.getTopLevelLoops()) {
      SmallPriorityWorklist<Loop *, 4> Worklist;
      appendNestedLoopsToWorklist(*L, Worklist);
      while (!Worklist.empty()) {
        // Hoist the loop invariant instructions in the innermost loop first,
        // and then all the way up.
        auto *L = Worklist.pop_back_val();
        Changed |= Impl.run(*L);
      }
    }
    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

bool SimpleLoopInvariantCodeMotionImpl::run(Loop &L) const {
  if (!isCandidate(L))
    return false;

  errs() << "SLICM @ " << L.getHeader()->getName() << "\n";
  auto *Preheader = L.getLoopPreheader();
  assert(Preheader && "Loop must have a preheader");

  SmallPtrSet<Instruction *, 4> LIs;
  // Until we reach a fixed point, find all loop invariant instructions.
  ssize_t NumLIs = -1;
  while (NumLIs != LIs.size()) {
    NumLIs = LIs.size();
    for (auto *BB : L.getBlocks()) {
      for (auto &I : *BB) {
        // Is in subloop; should already be hoisted.
        if (LI.getLoopFor(I.getParent()) != &L)
          continue;

        if (LIs.contains(&I))
          continue;

        if (hasLoopInvariantOperands(I, LIs))
          LIs.insert(&I);
      }
    }
  }

  // Hoist the instructions in the order they appear in the loop.
  unsigned NumHoisted = 0;
  for (auto *BB : L.blocks()) {
    for (auto &I : make_early_inc_range(*BB)) {
      if (!LIs.contains(&I))
        continue;

      if (isSafeToHoist(I, L)) {
        errs() << "Hoisting: " << I << "\n";
        I.moveBefore(Preheader->getTerminator());
        ++NumHoisted;
      }
    }
  }

  return !!NumHoisted;
}

bool SimpleLoopInvariantCodeMotionImpl::isCandidate(Loop &L) const {
  // SLICM moves code to the preheader, so the loop must have a preheader.
  if (!L.isLoopSimplifyForm()) {
    errs() << "Loop is not in loop simplify form\n";
    return false;
  }

  return true;
}

bool SimpleLoopInvariantCodeMotionImpl::isSafeToHoist(Instruction &I,
                                                      Loop &L) const {
  if (I.isTerminator()) {
    return false;
  }

  // To be safe to hoist, the instruction must either dominates all of its uses
  // or all loop exits. However, it's generally hard for the latter case to
  // fulfill as the loop may execute zero times. It's possible to relax this
  // condition if:
  // 1. The assigned-to variable is dead after the loop, e.g., not used outside
  // the loop, and
  // 2. The instruction can’t have side effects, including exceptions—generally
  // ruling out division because it might divide by zero.

  bool AllUsesInLoop = true;
  for (auto &U : I.uses()) {
    if (!DT.dominates(&I, U))
      return false;

    AllUsesInLoop &= L.contains(cast<Instruction>(U.getUser()));
  }

  if (!AllUsesInLoop || I.mayHaveSideEffects()) {
    // Since the relaxed condition is not met, we need to check if the
    // instruction dominates all loop exits.
    SmallVector<BasicBlock *, 4> ExitBlocks;
    L.getExitBlocks(ExitBlocks);
    if (!dominatesAll(I, ExitBlocks))
      return false;
  }

  return true;
}

bool SimpleLoopInvariantCodeMotionImpl::hasLoopInvariantOperands(
    Instruction &I, const SmallPtrSetImpl<Instruction *> &LIs) const {
  Loop *L = LI.getLoopFor(I.getParent());
  assert(L && "Instruction not in a loop");

  // If all operands are loop invariant, or are defined outside the loop,
  // then the instruction is loop invariant.
  for (auto &Op : I.operands()) {
    if (auto *OpI = dyn_cast<Instruction>(Op)) {
      if (L->contains(OpI) && !LIs.contains(OpI)) {
        return false;
      }
    }
  }
  return true;
}

bool SimpleLoopInvariantCodeMotionImpl::dominatesAll(
    Instruction &I, ArrayRef<BasicBlock *> Blocks) const {
  return all_of(Blocks, [&](BasicBlock *BB) { return DT.dominates(&I, BB); });
}

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, PluginName, LLVM_VERSION_STRING,
          [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef Name, FunctionPassManager &FPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == PassName) {
                    FPM.addPass(SimpleLoopInvariantCodeMotionPass());
                    return true;
                  }
                  return false;
                });
          }};
}
