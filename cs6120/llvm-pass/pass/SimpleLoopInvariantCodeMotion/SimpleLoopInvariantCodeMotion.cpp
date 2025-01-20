#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {

constexpr char PassName[] = "slicm";
constexpr char PluginName[] = "Simple Loop Invariant Code Motion";

class SimpleLoopInvariantCodeMotionImpl {
public:
  SimpleLoopInvariantCodeMotionImpl(LoopInfo &LI) : LI(LI) {}

  bool run(Loop &L) const;

  /// Check if the loop \p L is in the candidate form.
  bool isCandidate(Loop &L) const;

private:
  LoopInfo &LI;
};

class SimpleLoopInvariantCodeMotionPass
    : public PassInfoMixin<SimpleLoopInvariantCodeMotionPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &FAM) {
    errs() << "SLICM @ " << F.getName() << "\n";
    auto &LI = FAM.getResult<LoopAnalysis>(F);
    SimpleLoopInvariantCodeMotionImpl Impl(LI);
    bool Changed = false;
    for (Loop *L : LI) {
      Changed |= Impl.run(*L);
    }
    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

bool SimpleLoopInvariantCodeMotionImpl::run(Loop &L) const {
  if (!isCandidate(L))
    return false;

  errs() << "SLICM @ " << L.getHeader()->getName() << "\n";
  // TODO: Implement the actual transformation.
  return true;
}

bool SimpleLoopInvariantCodeMotionImpl::isCandidate(Loop &L) const {
  // SLICM moves code to the preheader, so the loop must have a preheader.
  if (!L.isLoopSimplifyForm()) {
    errs() << "Loop is not in loop simplify form\n";
    return false;
  }

  return true;
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
