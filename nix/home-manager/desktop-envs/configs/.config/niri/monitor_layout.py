# ruff: noqa: INP001

import argparse
import logging
import math
import time
from typing import TypedDict, cast

from niri_ipc import Request, connection

_logger = logging.getLogger(__name__)


class LogicalOutput(TypedDict):
    x: int
    y: int
    width: int
    height: int
    scale: float


class Mode(TypedDict):
    width: int


class Output(TypedDict):
    logical: LogicalOutput | None
    current_mode: int | None
    modes: list[Mode]
    physical_size: list[int] | None


def automatic_scale(output: Output, dpi: float) -> float | None:
    mode = output["current_mode"]
    physical_size = output["physical_size"]
    if mode is None or physical_size is None or physical_size[0] <= 0:
        return None
    physical_dpi = output["modes"][mode]["width"] * 25.4 / physical_size[0]
    return max(1.0, min(10.0, round(physical_dpi / dpi, 1)))


def apply_scales(request: Request, outputs: dict[str, Output], main: str, dpi: float) -> bool:
    changed = False
    for name, output in outputs.items():
        logical = output["logical"]
        if name == main or logical is None:
            continue
        scale = automatic_scale(output, dpi)
        if scale is None or math.isclose(logical["scale"], scale):
            continue
        _logger.info(f"Scaling {name} to {scale}")
        request({"Output": {"output": name, "action": {"Scale": {"scale": {"Specific": scale}}}}})
        changed = True
    return changed


def positions(outputs: dict[str, LogicalOutput], main: str) -> dict[str, tuple[int, int]]:
    external = sorted(name for name in outputs if name != main)
    width = sum(outputs[name]["width"] for name in external)
    x = (outputs[main]["width"] - width) // 2 if main in outputs else 0
    bottom = 0 if main in outputs else max((output["height"] for output in outputs.values()), default=0)
    result = {}
    for name in external:
        result[name] = (x, bottom - outputs[name]["height"])
        x += outputs[name]["width"]
    if main in outputs:
        result[main] = (0, 0)
    return result


def apply_positions(request: Request, outputs: dict[str, LogicalOutput], main: str) -> bool:
    changed = False
    for name, (x, y) in positions(outputs, main).items():
        if (outputs[name]["x"], outputs[name]["y"]) == (x, y):
            continue
        _logger.info(f"Positioning {name} at ({x}, {y})")
        request({"Output": {"output": name, "action": {"Position": {"position": {"Specific": {"x": x, "y": y}}}}}})
        changed = True
    return changed


def apply_layout(request: Request, main: str, external_dpi: float | None = None) -> bool:
    reply = cast("dict[str, dict[str, Output]]", request("Outputs"))
    if external_dpi is not None and apply_scales(request, reply["Outputs"], main, external_dpi):
        # Position on the next poll, after Niri has updated the logical dimensions for the new scales.
        return True
    outputs = {name: output["logical"] for name, output in reply["Outputs"].items() if output["logical"] is not None}
    return apply_positions(request, outputs, main)


def main() -> None:
    parser = argparse.ArgumentParser(description="Arrange external monitors in a row above the laptop display.")
    parser.add_argument("main", help="Laptop output connector, e.g. eDP-1.")
    parser.add_argument("--external-dpi", type=float, help="Target logical DPI for automatic external monitor scaling.")
    parser.add_argument("--once", action="store_true", help="Exit when the layout has settled.")
    args = parser.parse_args()
    external_dpi = cast("float | None", args.external_dpi)
    if external_dpi is not None and (not math.isfinite(external_dpi) or external_dpi <= 0):
        parser.error("--external-dpi must be finite and greater than zero")
    logging.basicConfig(level=logging.INFO)
    with connection() as request:
        while True:
            changed = apply_layout(request, cast("str", args.main), external_dpi)
            if args.once and not changed:
                break
            # Niri 26.04 has no output-change event; polling also catches scale changes and config reloads.
            time.sleep(1)


if __name__ == "__main__":
    main()
