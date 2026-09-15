# ruff: noqa: INP001

import argparse
import fcntl
import json
import logging
import os
import socket
import sys
import time
from collections.abc import Callable, Iterator
from contextlib import contextmanager, suppress
from dataclasses import dataclass, field
from enum import StrEnum
from pathlib import Path
from typing import TypedDict, cast

_logger = logging.getLogger(__name__)


class Action(StrEnum):
    STACK_LEFT = "stack-left"
    STACK_RIGHT = "stack-right"

    @property
    def offset(self) -> int:
        return -1 if self is Action.STACK_LEFT else 1


class WindowLayout(TypedDict):
    pos_in_scrolling_layout: list[int] | None
    tile_size: list[float]
    window_size: list[int]


class Window(TypedDict):
    id: int
    workspace_id: int | None
    is_focused: bool
    is_floating: bool
    layout: WindowLayout


class LogicalOutput(TypedDict):
    width: int


class Output(TypedDict):
    logical: LogicalOutput | None


type NiriAction = tuple[str, dict[str, object]]
type Request = Callable[[str | dict[str, object]], object]


@contextmanager
def connection() -> Iterator[Request]:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(2)
        client.connect(os.environ["NIRI_SOCKET"])
        with client.makefile("rb") as response:

            def request(payload: str | dict[str, object]) -> object:
                client.sendall(json.dumps(payload).encode() + b"\n")
                reply = json.loads(response.readline())
                if "Err" in reply:
                    raise RuntimeError(reply["Err"])
                return cast("object", reply["Ok"])

            yield request


def get_windows(request: Request) -> list[Window]:
    reply = cast("dict[str, object]", request("Windows"))
    return cast("list[Window]", reply["Windows"])


def get_focused_output(request: Request) -> Output | None:
    reply = cast("dict[str, Output | None]", request("FocusedOutput"))
    return reply["FocusedOutput"]


def send_commands(request: Request, commands: list[NiriAction]) -> None:
    for name, arguments in commands:
        request({"Action": {name: arguments}})


def wait_for_windows(request: Request, ready: Callable[[list[Window]], bool]) -> None:
    deadline = time.monotonic() + 0.5
    while not ready(get_windows(request)):
        if time.monotonic() >= deadline:
            message = "The requested layout did not settle."
            raise RuntimeError(message)
        time.sleep(0.01)


def workspace_columns(windows: list[Window], workspace: int) -> list[list[int]]:
    ordered = []
    for window in windows:
        position = window["layout"]["pos_in_scrolling_layout"]
        if window["workspace_id"] == workspace and not window["is_floating"] and position is not None:
            ordered.append((position[0], position[1], window["id"]))
    columns: dict[int, list[int]] = {}
    for column, _, window_id in sorted(ordered):
        columns.setdefault(column, []).append(window_id)
    return list(columns.values())


@dataclass
class LayoutPlan:
    main: int
    workspace: int
    view_width: int
    full_width: float
    expected_columns: list[list[int]]
    pair: list[int] = field(default_factory=list)
    released: list[int] = field(default_factory=list)
    layout_commands: list[NiriAction] = field(default_factory=list)
    focus_commands: list[NiriAction] = field(default_factory=list)

    def add_layout_command(self, name: str, **arguments: object) -> None:
        self.layout_commands.append((name, arguments))

    def column_index(self, window_id: int) -> int:
        return next(index for index, column in enumerate(self.expected_columns) if window_id in column)

    def ready_to_focus(self, windows: list[Window]) -> bool:
        if workspace_columns(windows, self.workspace) != self.expected_columns:
            return False
        if any(
            window["layout"]["window_size"][0] <= self.view_width / 2
            for window in windows
            if window["id"] in self.released
        ):
            return False
        if not self.pair:
            return any(
                window["id"] == self.main and window["layout"]["window_size"][0] > self.view_width / 2
                for window in windows
            )
        return all(
            window["layout"]["window_size"][0] <= self.view_width / 2 for window in windows if window["id"] in self.pair
        )

    def settled(self, windows: list[Window]) -> bool:
        if not self.ready_to_focus(windows):
            return False
        return any(window["id"] == self.main and window["is_focused"] for window in windows)


def find_active_stack(step: LayoutPlan, windows: list[Window]) -> int | None:
    columns = step.expected_columns
    main_index = step.column_index(step.main)
    if len(columns[main_index]) != 1:
        return None
    by_id = {window["id"]: window for window in windows}
    main_width = by_id[step.main]["layout"]["tile_size"][0]
    if main_width > step.view_width / 2:
        return None
    # Niri 26.04 exposes viewport coordinates only for floating windows, not tiled columns.
    candidates = []
    for action in Action:
        index = main_index + action.offset
        if not 0 <= index < len(columns):
            continue
        width = max(by_id[window_id]["layout"]["tile_size"][0] for window_id in columns[index])
        if abs(main_width - width) <= 1:
            candidates.append(index)
    if len(candidates) > 1:
        message = "Both neighboring columns have matching half widths; expand the unused column before stacking."
        raise RuntimeError(message)
    return candidates[0] if candidates else None


def grow_stack(step: LayoutPlan, action: Action, stack_index: int | None) -> bool:
    columns = step.expected_columns
    main_index = step.column_index(step.main)
    stack = columns[stack_index] if stack_index is not None else []
    inward = "ConsumeOrExpelWindowLeft" if action is Action.STACK_RIGHT else "ConsumeOrExpelWindowRight"
    if not stack and len(columns[main_index]) > 1:
        step.add_layout_command(inward, id=step.main)
        columns[main_index].remove(step.main)
        columns.insert(main_index + (action is Action.STACK_LEFT), [step.main])
    source_index = step.column_index(stack[0] if stack else step.main) + action.offset
    if not 0 <= source_index < len(columns):
        return False
    source = columns[source_index]
    candidate = source[0]
    if len(source) > 1:
        # Isolate the candidate between its source column and the destination before consuming it.
        step.add_layout_command(inward, id=candidate)
    source.remove(candidate)
    if stack:
        step.add_layout_command(inward, id=candidate)
        stack.append(candidate)
        if not source:
            columns.pop(source_index)
    else:
        stack = [candidate]
        if source:
            columns.insert(source_index + (action is Action.STACK_LEFT), stack)
        else:
            columns[source_index] = stack
    step.pair = [step.main, *stack]
    return True


def shrink_stack(step: LayoutPlan, stack_index: int) -> None:
    columns = step.expected_columns
    stack = columns[stack_index]
    if len(stack) <= 1:
        step.pair = []
        step.released = stack.copy()
        for window_id in [step.main, *step.released]:
            step.add_layout_command("SetWindowWidth", id=window_id, change={"SetProportion": step.full_width})
            step.add_layout_command("ResetWindowHeight", id=window_id)
        step.add_layout_command("FocusWindow", id=step.main)
        step.focus_commands.append(("CenterColumn", {}))
        return
    on_right = stack_index > step.column_index(step.main)
    outward = "ConsumeOrExpelWindowRight" if on_right else "ConsumeOrExpelWindowLeft"
    expelled = stack.pop()
    step.add_layout_command(outward, id=expelled)
    # Full-width released columns cannot be mistaken for the active side stack on a later press.
    step.add_layout_command("SetWindowWidth", id=expelled, change={"SetProportion": step.full_width})
    step.add_layout_command("ResetWindowHeight", id=expelled)
    columns.insert(stack_index + on_right, [expelled])
    step.pair = [step.main, *stack]
    step.released = [expelled]


def plan(
    windows: list[Window], focused: Window, view_width: int, action: Action, full_width: float
) -> LayoutPlan | None:
    workspace = focused["workspace_id"]
    if workspace is None:
        return None
    columns = workspace_columns(windows, workspace)
    main = focused["id"]
    if not any(main in column for column in columns):
        return None
    step = LayoutPlan(
        main=main, workspace=workspace, view_width=view_width, full_width=full_width, expected_columns=columns
    )
    stack_index = find_active_stack(step, windows)
    if stack_index is not None and stack_index != step.column_index(main) + action.offset:
        shrink_stack(step, stack_index)
    elif not grow_stack(step, action, stack_index):
        return None
    if not step.pair:
        return step

    for window_id in (main, step.pair[1]):
        step.add_layout_command("SetWindowWidth", id=window_id, change={"SetProportion": 50.0})
    for window_id in step.pair:
        step.add_layout_command("ResetWindowHeight", id=window_id)
    step.add_layout_command("FocusWindow", id=step.pair[1])
    step.add_layout_command("SetColumnDisplay", display="Normal")
    step.focus_commands.append(("FocusWindow", {"id": main}))
    return step


def parse_args() -> tuple[Action, float]:
    parser = argparse.ArgumentParser(description="Grow a side stack, or shrink the opposite stack.")
    parser.add_argument("action", type=Action, choices=list(Action))
    parser.add_argument(
        "--full-width", type=float, required=True, metavar="PERCENT", help="Column width after unstacking, in percent."
    )
    args = parser.parse_args()
    full_width = cast("float", args.full_width)
    if not 50 < full_width <= 100:  # noqa: PLR2004
        parser.error(
            "--full-width must be greater than 50 and at most 100 to remain distinct from the half-width stack"
        )
    return cast("Action", args.action), full_width


def apply_step(request: Request, action: Action, full_width: float) -> None:
    windows = get_windows(request)
    focused = next((window for window in windows if window["is_focused"]), None)
    if focused is None or focused["is_floating"] or focused["workspace_id"] is None:
        return
    output = get_focused_output(request)
    if output is None or output["logical"] is None:
        return
    step = plan(windows, focused, output["logical"]["width"], action, full_width)
    if step is None:
        return
    try:
        send_commands(request, step.layout_commands)
        # Wait for clients to resize before niri decides whether to center an overflowing pair.
        wait_for_windows(request, step.ready_to_focus)
        send_commands(request, step.focus_commands)
        # The next press infers its state from column sizes, so wait for the released windows to expand too.
        wait_for_windows(request, step.settled)
    except (OSError, RuntimeError):
        with suppress(OSError, RuntimeError):
            request({"Action": {"FocusWindow": {"id": step.main}}})
        raise


def main() -> None:
    action, full_width = parse_args()
    socket_name = Path(os.environ["NIRI_SOCKET"]).name
    lock_path = Path(os.environ["XDG_RUNTIME_DIR"]) / f"niri-layout-step-{socket_name}.lock"
    with lock_path.open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        with connection() as request:
            apply_step(request, action, full_width)


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, KeyError, json.JSONDecodeError):
        _logger.exception("niri layout step failed")
        sys.exit(1)
