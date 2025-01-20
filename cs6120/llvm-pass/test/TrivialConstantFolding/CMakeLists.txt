add_custom_target(check-tcf
  # Always re-build the *.ll files with the latest version of the pass
  # since the Makefile doesn't know how to track dependencies on the pass.
  COMMAND make -C "${CMAKE_CURRENT_SOURCE_DIR}" test -B
  DEPENDS TrivialConstantFoldingPass)
