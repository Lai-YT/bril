#!/usr/bin/env python3

"""Trivial Dead Code Elimination."""

import argparse
import json
import sys
from typing import Any, Callable, Dict, List, Set

from cfg import form_blocks
from type import Instr


def remove_def_with_no_use(instrs: List[Instr]) -> List[Instr]:
    """Remove definitions with no uses.

    Args:
        instrs: A list of instructions.

    Returns:
        A list of instructions with definitions that have no uses removed.
    """
    used: Set[str] = set()
    for instr in instrs:
        if "args" in instr:  # is a use
            used = used.union(instr["args"])
    if not used:
        return instrs
    # Now, all variables that have uses are collected.
    # We walk through the instructions again and remove defs without a use.
    return [instr for instr in instrs if "dest" not in instr or instr["dest"] in used]


def remove_re_def_with_no_use_between(instrs: List[Instr]) -> List[Instr]:
    """Remove re-definitions with no uses between them.

    Args:
        instrs: A list of instructions.

    Returns:
        A list of instructions with re-definitions that have no uses between them removed.
    """
    for block in form_blocks(instrs):
        unused: Dict[str, Instr] = {}
        for instr in block:
            # An instruction may use and define a variable at the same time;
            # such a variable is considered used, followed by a new def that is unused.
            if "args" in instr:  # is a use
                for arg in instr["args"]:
                    unused.pop(arg, None)
            if "dest" in instr:  # is a def
                if instr["dest"] in unused:
                    # Mark the instruction as dead, so we know it should be removed from the program.
                    unused[instr["dest"]]["is_dead"] = True
                unused[instr["dest"]] = instr
    # Now, the dead defs are collected; remove them from the program.
    return [instr for instr in instrs if "is_dead" not in instr]


def main(passes: List[Callable[[List[Instr]], List[Instr]]]) -> None:
    prog: Dict[str, List[Dict[str, Any]]] = json.load(sys.stdin)

    for func in prog["functions"]:
        for pass_ in passes:
            while True:
                instrs: List[Instr] = func["instrs"]
                res = pass_(instrs)
                if len(res) == len(instrs):
                    # converges
                    break
                func["instrs"] = res

    json.dump(prog, indent=2, fp=sys.stdout)


# Command-line entry points.


def tdce() -> None:
    main([remove_def_with_no_use])


def tdce_plus() -> None:
    main([remove_def_with_no_use, remove_re_def_with_no_use_between])


MODES = {
    "tdce": tdce,
    "tdce+": tdce_plus,
}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        sys.argv[0],
        description="""
This module defines two kinds of tdce optimization:
(1) `tdce`: Removes defs with no use. This is a global optimization. (default)
(2) `tdce+`: Augments `tdce` by removing defs that have been re-defined later without a use in between. This has no effect if the program is already in SSA-form.
""",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("mode", choices=MODES, default="tdce", nargs="?")
    args = parser.parse_args()
    MODES[args.mode]()
