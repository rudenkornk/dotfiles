#!/usr/bin/env python3
"""Parse tmux window_layout and detect pane split orientation."""

from __future__ import annotations

import argparse
import subprocess
import sys
from dataclasses import dataclass, field
from enum import Enum

HIGH_PRIO_CMDS = {"vim", "nvim", "opencode"}


class Direction(Enum):
    HORIZONTAL = "horizontal"
    VERTICAL = "vertical"


@dataclass
class Pane:
    width: int
    height: int
    x: int
    y: int
    pane_id: int


@dataclass
class Container:
    width: int
    height: int
    x: int
    y: int
    direction: Direction
    children: list[Pane | Container] = field(default_factory=list)


class _Parser:
    def __init__(self, s: str) -> None:
        self._s = s
        self._pos = 0

    def parse(self) -> Pane | Container:
        # skip checksum (hex digits before first comma)
        self._pos = self._s.index(",") + 1
        return self._node()

    def _node(self) -> Pane | Container:
        w = self._int()
        self._expect("x")
        h = self._int()
        self._expect(",")
        x = self._int()
        self._expect(",")
        y = self._int()
        ch = self._s[self._pos]
        if ch in "{[":
            direction = Direction.HORIZONTAL if ch == "{" else Direction.VERTICAL
            close = "}" if ch == "{" else "]"
            self._pos += 1
            children: list[Pane | Container] = []
            while self._s[self._pos] != close:
                children.append(self._node())
                if self._s[self._pos] == ",":
                    self._pos += 1
            self._pos += 1  # skip closing bracket
            return Container(w, h, x, y, direction, children)

        self._expect(",")
        pane_id = self._int()
        return Pane(w, h, x, y, pane_id)

    def _int(self) -> int:
        start = self._pos
        while self._pos < len(self._s) and self._s[self._pos].isdigit():
            self._pos += 1
        return int(self._s[start : self._pos])

    def _expect(self, ch: str) -> None:
        if self._s[self._pos] != ch:
            msg = f"Expected {ch!r} at pos {self._pos}, got {self._s[self._pos]!r}"
            raise ValueError(msg)
        self._pos += 1


def parse_layout(layout: str) -> Pane | Container:
    return _Parser(layout).parse()


def collect_panes(root: Pane | Container) -> list[Pane]:
    """Flatten the layout tree into a list of all Pane leaves."""
    if isinstance(root, Pane):
        return [root]
    result: list[Pane] = []
    for child in root.children:
        result.extend(collect_panes(child))
    return result


def find_pane(root: Pane | Container, pane_id: int) -> Pane:
    """Return the Pane node for the given ID. Raises PaneNotFoundError if absent."""
    for pane in collect_panes(root):
        if pane.pane_id == pane_id:
            return pane
    raise PaneNotFoundError(pane_id)


class PaneNotFoundError(Exception):
    pass


def find_split(root: Pane | Container, pane_id: int) -> Direction | None:
    """Return the split direction the pane belongs to, or None if it is alone.

    Raises PaneNotFoundError if the pane is not in the layout.
    """
    if isinstance(root, Pane):
        if root.pane_id == pane_id:
            return None  # sole pane, no split
        raise PaneNotFoundError(pane_id)

    for child in root.children:
        if isinstance(child, Pane) and child.pane_id == pane_id:
            return root.direction
        if isinstance(child, Container):
            try:
                return find_split(child, pane_id)
            except PaneNotFoundError:
                continue

    raise PaneNotFoundError(pane_id)


def adjacent_directions(target: Pane, all_panes: list[Pane]) -> dict[str, list[Pane]]:
    """Return panes directly adjacent to target, grouped by direction.

    A pane is directly adjacent if its edge is exactly 1 cell away (the tmux
    separator) and the perpendicular spans overlap.
    """
    result: dict[str, list[Pane]] = {"left": [], "right": [], "above": [], "below": []}
    for pane in all_panes:
        if pane.pane_id == target.pane_id:
            continue
        t_right = target.x + target.width
        t_bottom = target.y + target.height
        p_right = pane.x + pane.width
        p_bottom = pane.y + pane.height
        y_overlap = max(target.y, pane.y) < min(t_bottom, p_bottom)
        x_overlap = max(target.x, pane.x) < min(t_right, p_right)
        if pane.x == t_right + 1 and y_overlap:
            result["right"].append(pane)
        elif target.x == p_right + 1 and y_overlap:
            result["left"].append(pane)
        elif pane.y == t_bottom + 1 and x_overlap:
            result["below"].append(pane)
        elif target.y == p_bottom + 1 and x_overlap:
            result["above"].append(pane)
    return result


def _tmux(*args: str) -> str:
    result = subprocess.run(  # noqa: S603
        ["tmux", *args],  # noqa: S607
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def _tmux_display(fmt: str, target: str | None = None) -> str:
    args = ["display-message", "-p"]
    if target is not None:
        args += ["-t", target]
    args.append(fmt)
    return _tmux(*args)


def _parse_pane_id(raw: str) -> int:
    return int(raw.lstrip("%"))


def get_pane_commands() -> dict[int, str]:
    """Return a mapping of pane_id -> pane_current_command for all panes."""
    output = _tmux("list-panes", "-F", "#{pane_id} #{pane_current_command}")
    result: dict[int, str] = {}
    for line in output.splitlines():
        raw_id, _, cmd = line.partition(" ")
        result[_parse_pane_id(raw_id)] = cmd
    return result


def find_path(root: Pane | Container, pane_id: int) -> list[Container]:
    """Return the list of Container ancestors from root down to the pane's direct parent.

    Returns an empty list if root is the pane itself.
    Raises PaneNotFoundError if the pane is not in the layout.
    """
    if isinstance(root, Pane):
        if root.pane_id == pane_id:
            return []
        raise PaneNotFoundError(pane_id)

    for child in root.children:
        if isinstance(child, Pane) and child.pane_id == pane_id:
            return [root]
        if isinstance(child, Container):
            try:
                sub = find_path(child, pane_id)
            except PaneNotFoundError:
                continue
            else:
                return [root, *sub]

    raise PaneNotFoundError(pane_id)


def detect_orientation(root: Pane | Container, pane_id: int) -> Direction | None:
    """Detect preferred split orientation based on adjacent high-priority panes.

    Falls back to find_split when high-prio panes are on both axes or absent.
    Returns None only when the pane is alone (find_split fallback returns None).
    """
    target = find_pane(root, pane_id)
    all_panes = collect_panes(root)
    adj = adjacent_directions(target, all_panes)
    commands = get_pane_commands()

    has_lr = any(commands.get(p.pane_id, "") in HIGH_PRIO_CMDS for p in adj["left"] + adj["right"])
    has_tb = any(commands.get(p.pane_id, "") in HIGH_PRIO_CMDS for p in adj["above"] + adj["below"])

    if has_lr and not has_tb:
        return Direction.HORIZONTAL
    if has_tb and not has_lr:
        return Direction.VERTICAL
    return find_split(root, pane_id)


def _resize_axis(pane_id: int, axis: str, value: int) -> None:
    flag = "-x" if axis == "x" else "-y"
    _tmux("resize-pane", "-t", f"%{pane_id}", flag, str(value))


def _size_up(root: Pane | Container, pane_id: int, pane: Pane) -> None:
    need_x = pane.width == 1
    need_y = pane.height == 1

    if need_x and need_y:
        orientation = detect_orientation(root, pane_id)
        if orientation is Direction.HORIZONTAL:
            need_y = False
        elif orientation is Direction.VERTICAL:
            need_x = False
        else:
            return  # sole pane

    ancestors = list(reversed(find_path(root, pane_id)))  # innermost first

    if need_x:
        container = next((c for c in ancestors if c.direction is Direction.HORIZONTAL), None)
        if container is not None:
            _resize_axis(pane_id, "x", container.width // len(container.children))

    if need_y:
        container = next((c for c in ancestors if c.direction is Direction.VERTICAL), None)
        if container is not None:
            _resize_axis(pane_id, "y", container.height // len(container.children))


def toggle_pane(root: Pane | Container, pane_id: int) -> None:
    """Toggle pane size between expanded and minimised (1 cell)."""
    pane = find_pane(root, pane_id)

    if pane.width > 1 and pane.height > 1:
        orientation = detect_orientation(root, pane_id)
        if orientation is Direction.HORIZONTAL:
            _resize_axis(pane_id, "x", 1)
        elif orientation is Direction.VERTICAL:
            _resize_axis(pane_id, "y", 1)
        return

    _size_up(root, pane_id, pane)


def _add_common_args(p: argparse.ArgumentParser) -> None:
    p.add_argument("--layout", default=None, help="window_layout string (default: query tmux)")
    p.add_argument("--pane", default=None, help="pane id like %%49 or 49 (default: current pane)")


def _resolve_common(args: argparse.Namespace) -> tuple[Pane | Container, int, str]:
    layout_str: str = args.layout if args.layout is not None else _tmux_display("#{window_layout}")
    pane_raw: str = args.pane if args.pane is not None else _tmux_display("#{pane_id}")
    return parse_layout(layout_str), _parse_pane_id(pane_raw), pane_raw


def main() -> None:
    parser = argparse.ArgumentParser(description="tmux pane layout utilities.")
    subparsers = parser.add_subparsers(dest="command")

    detect_parser = subparsers.add_parser("detect", help="Print split orientation of a pane.")
    _add_common_args(detect_parser)

    toggle_parser = subparsers.add_parser("toggle", help="Toggle pane between expanded and minimised.")
    _add_common_args(toggle_parser)

    args = parser.parse_args()

    if args.command is None:
        parser.print_usage()
        sys.exit(1)

    root, pane_id, pane_raw = _resolve_common(args)

    if args.command == "detect":
        try:
            result = detect_orientation(root, pane_id)
        except PaneNotFoundError:
            print(f"error: pane {pane_raw} not found in layout", file=sys.stderr)  # noqa: T201
            sys.exit(1)
        print(result.value if result is not None else "none")  # noqa: T201

    elif args.command == "toggle":
        try:
            toggle_pane(root, pane_id)
        except PaneNotFoundError:
            print(f"error: pane {pane_raw} not found in layout", file=sys.stderr)  # noqa: T201
            sys.exit(1)


if __name__ == "__main__":
    main()
