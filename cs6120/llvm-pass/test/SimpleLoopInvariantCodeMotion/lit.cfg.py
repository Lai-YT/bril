from pathlib import Path

import lit.formats

config.name = "SimpleLoopInvariantCodeMotion"
config.test_format = lit.formats.ShTest(True)

config.test_source_root = Path(__file__).parent
config.test_exec_root = config.slicm_test_build_dir

config.suffixes = [".ll"]

config.substitutions.append(("%opt", "opt-17"))
config.substitutions.append(("%slicm_build_dir", config.slicm_build_dir))
