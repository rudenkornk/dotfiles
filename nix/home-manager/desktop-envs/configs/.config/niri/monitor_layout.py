# ruff: noqa: INP001

import argparse
import logging
import math
import time
from typing import TypedDict, cast

from niri_ipc import Request, connection

_logger = logging.getLogger(__name__)

# The pinned 16 px JetBrainsMono NF specimen in calibration.html is 528 logical pixels wide.
REFERENCE_WIDTH_LOGICAL_PX = 528.0
# At 3840 px width: scale 1.3 on the 340 mm-wide laptop and 1.15 on the 600 mm-wide external monitor.
CALIBRATION_POINTS = ((340 * 210, 60.775), (600 * 340, 94.875))
# Row 6 on eDP-1: a 12 px font at 4/3 scale, equivalent to the reference at 1:1.
MIN_REFERENCE_WIDTH_PHYSICAL_PX = 528.0


class LogicalOutput(TypedDict):
    x: int
    y: int
    width: int
    height: int
    scale: float
    transform: str


class Mode(TypedDict):
    width: int
    height: int


class Output(TypedDict):
    logical: LogicalOutput | None
    current_mode: int | None
    modes: list[Mode]
    physical_size: list[int] | None


def preferred_width_mm(area_mm2: float) -> float:
    (small_area, small_width), (large_area, large_width) = CALIBRATION_POINTS
    exponent = math.log(large_width / small_width) / math.log(large_area / small_area)
    return small_width * math.pow(area_mm2 / small_area, exponent)


def minimum_width_mm(pixels_per_mm: float) -> float:
    return MIN_REFERENCE_WIDTH_PHYSICAL_PX / pixels_per_mm


def niri_scale(width_mm: float, pixels_per_mm: float) -> float:
    scale = width_mm * pixels_per_mm / REFERENCE_WIDTH_LOGICAL_PX
    # Ignore one ULP of arithmetic noise before rounding upward to Niri's 1/120 scale steps.
    return math.ceil(math.nextafter(scale * 120, -math.inf)) / 120


def calibrated_scale(output: Output) -> float | None:
    mode_index = output["current_mode"]
    physical_size = output["physical_size"]
    logical = output["logical"]
    if mode_index is None or physical_size is None or min(physical_size) <= 0 or logical is None:
        return None
    mode = output["modes"][mode_index]
    rotated = logical["transform"] in {"90", "270", "Flipped90", "Flipped270"}
    pixel_width = mode["height"] if rotated else mode["width"]
    physical_width = physical_size[1] if rotated else physical_size[0]
    pixels_per_mm = pixel_width / physical_width
    area_mm2 = physical_size[0] * physical_size[1]

    preferred_mm = preferred_width_mm(area_mm2)
    minimum_mm = minimum_width_mm(pixels_per_mm)
    final_mm = max(preferred_mm, minimum_mm)
    return niri_scale(final_mm, pixels_per_mm)


def apply_scales(request: Request, outputs: dict[str, Output], scales: dict[str, float | None]) -> bool:
    changed = False
    for name, scale in scales.items():
        logical = outputs[name]["logical"]
        if logical is None:
            continue
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


def apply_layout(request: Request, main: str, *, auto_scale: bool) -> bool:
    reply = cast("dict[str, dict[str, Output]]", request("Outputs"))
    scales = {name: calibrated_scale(output) for name, output in reply["Outputs"].items() if auto_scale}
    if apply_scales(request, reply["Outputs"], scales):
        # Position on the next poll, after Niri has updated the logical dimensions for the new scales.
        return True
    outputs = {name: output["logical"] for name, output in reply["Outputs"].items() if output["logical"] is not None}
    return apply_positions(request, outputs, main)


def main() -> None:
    parser = argparse.ArgumentParser(description="Arrange external monitors in a row above the laptop display.")
    parser.add_argument("main", help="Laptop output connector, e.g. eDP-1.")
    parser.add_argument(
        "--auto-scale", action="store_true", help="Apply calibrated physical-size scaling to all monitors."
    )
    parser.add_argument("--once", action="store_true", help="Exit when the layout has settled.")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO)
    with connection() as request:
        while True:
            changed = apply_layout(request, cast("str", args.main), auto_scale=args.auto_scale)
            if args.once and not changed:
                break
            # Niri 26.04 has no output-change event; polling also catches scale changes and config reloads.
            time.sleep(1)


if __name__ == "__main__":
    main()
