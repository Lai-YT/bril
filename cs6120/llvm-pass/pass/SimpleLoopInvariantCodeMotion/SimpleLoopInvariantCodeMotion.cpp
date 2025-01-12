#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {

constexpr char PassName[] = "slicm";
constexpr char PluginName[] = "Simple Loop Invariant Code Motion";

class SimpleLoopInvariantCodeMotionPass
    : public PassInfoMixin<SimpleLoopInvariantCodeMotionPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &FAM) {
    errs() << "Simple Loop Invariant Code Motion @ " << F.getName() << "\n";
    return PreservedAnalyses::all();
  }
};

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
