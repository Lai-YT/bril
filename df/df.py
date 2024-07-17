"""The data flow solver."""

import argparse
import json
import sys
from collections import deque
from copy import deepcopy
from enum import Enum, auto
from typing import (
    Any,
    Callable,
    Deque,
    Dict,
    Iterable,
    List,
    OrderedDict,
    Set,
    Tuple,
    TypeVar,
)

import cprop
import defined

from cfg import Block, Instr, form_blocks, get_cfg, name_blocks


def find_predecessors(name2successors: Dict[str, List[str]]) -> Dict[str, List[str]]:
    """Finds the predecessors of blocks through their successors.

    Args:
        name2successors: A dictionary mapping block names to their successor block names.

    Returns:
        A dictionary mapping block names to their predecessor block names.
    """
    name2predecessors: Dict[str, List[str]] = {n: list() for n in name2successors}
    for name, successors in name2successors.items():
        for this_name in name2predecessors:
            if this_name in successors:
                name2predecessors[this_name].append(name)
    return name2predecessors


T = TypeVar("T")


def union(iterable: Iterable[Set[T]]) -> Set[T]:
    return set().union(*iterable)


def intersection(iterable: Iterable[Set[T]]) -> Set[T]:
    it = iter(iterable)
    try:
        first = next(it)
        return first.intersection(*it)
    except StopIteration:
        # The iterable contains no sets.
        return set()


class Analysis(Enum):
    # Reaching Definitions.
    DEFINED = auto()
    # Constant Propagation.
    CPROP = auto()

    def __str__(self) -> str:
        return self.name.lower()


class DataFlowSolver:

    def __init__(self, instrs: List[Instr], analysis: Analysis) -> None:
        self._instrs = instrs
        self._analysis = analysis

    def solve(self) -> Tuple[Dict[str, Set], Dict[str, Set]]:
        if self._analysis is Analysis.DEFINED:
            return self._solve(func["instrs"], set(), defined.out, union)
        elif self._analysis is Analysis.CPROP:
            return self._solve(func["instrs"], set(), cprop.out, intersection)
        else:
            raise ValueError(f"unknonw analysis {self._analysis}")

    # TODO: backward
    def _solve(
        self,
        instrs: List[Instr],
        init: Set[T],
        transfer: Callable[[Block, Set[T]], Set[T]],
        merge: Callable[[Iterable[Set[T]]], Set[T]],
    ) -> Tuple[Dict[str, Set[T]], Dict[str, Set[T]]]:
        """Solves the data flow analysis.

        Args:
            instrs: A list of instructions.
            init: The initial set of data flow values. Will be copied with `deepcopy`.
            transfer: A function to compute the OUT set from the IN set for a block.
            merge: A function to merge multiple IN sets.

        Returns:
            A tuple containing two dictionaries:
                - IN sets for each block.
                - OUT sets for each block.
        """
        # The first block is the entry block.
        blocks: OrderedDict[str, Block] = name_blocks(form_blocks(instrs))
        name2successors: Dict[str, List[str]] = get_cfg(blocks)
        name2predecessors: Dict[str, List[str]] = find_predecessors(name2successors)

        # in[entry] = init
        ins: Dict[str, Set[T]] = {n: set() for n in blocks}
        entry_name = list(blocks.keys())[0]
        ins[entry_name] = deepcopy(init)
        # out[*] = init
        outs: Dict[str, Set[T]] = {n: deepcopy(init) for n in blocks}

        # Represent the blocks with their names.
        worklist: Deque[str] = deque(blocks.keys())
        while worklist:
            # We can pick any block here.
            block_name = worklist.popleft()
            block = blocks[block_name]

            in_ = merge(outs[pred] for pred in name2predecessors[block_name])
            out = transfer(block, in_)

            # Until the basic block converges.
            if out != outs[block_name]:
                worklist += name2successors[block_name]

            ins[block_name] = in_
            outs[block_name] = out

        assert len(ins) == len(outs)
        return ins, outs


if __name__ == "__main__":
    parser = argparse.ArgumentParser(sys.argv[0])
    parser.add_argument(
        "analysis", choices=Analysis, type=lambda x: Analysis[x.upper()]
    )
    args = parser.parse_args()

    prog: Dict[str, List[Dict[str, Any]]] = json.load(sys.stdin)

    if args.analysis is Analysis.DEFINED:
        for func in prog["functions"]:
            solver = DataFlowSolver(func["instrs"], Analysis.DEFINED)
            ins, outs = solver.solve()
            for block_name in ins.keys():
                print(f"{block_name}:")
                print("  in:  ", end="")
                print(*sorted(ins[block_name]), sep=", ")
                print("  out: ", end="")
                print(*sorted(outs[block_name]), sep=", ")
    elif args.analysis is Analysis.CPROP:
        for func in prog["functions"]:
            solver = DataFlowSolver(func["instrs"], Analysis.CPROP)
            ins, outs = solver.solve()
            for block_name in ins.keys():
                print(f"{block_name}:")
                print(
                    "  in: ",
                    ", ".join(f"{name}: {val}" for name, val in ins[block_name]),
                )
                print(
                    "  out:",
                    ", ".join(f"{name}: {val}" for name, val in outs[block_name]),
                )
