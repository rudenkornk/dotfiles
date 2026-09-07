import json
import logging
from pathlib import Path
from typing import Any

from ..utils import run_shell

_logger = logging.getLogger(__name__)


_home = str(Path.home())


def _normalize_values(obj: dict[str, Any] | list[Any]) -> None:
    iter_obj = obj.items() if isinstance(obj, dict) else enumerate(obj)
    for k, v in iter_obj:
        if isinstance(v, float):
            obj[k] = float(f"{v:.3g}")  # type: ignore[index]  # pyright: ignore [reportArgumentType, reportCallIssue]
        elif isinstance(v, str) and (v == _home or v.startswith(_home + "/")):
            obj[k] = "~" + v.removeprefix(_home)  # type: ignore[index]  # pyright: ignore [reportArgumentType, reportCallIssue]
        elif isinstance(v, (dict, list)):
            _normalize_values(v)


def _extract_host_settings[T: list[Any] | dict[str, Any]](obj: T) -> T:
    host_settings = type(obj)()
    iter_obj = obj.copy().items() if isinstance(obj, dict) else enumerate(obj.copy())
    for k, v in iter_obj:
        if k in ("monitors", "lockScreenMonitors"):
            host_settings[k] = v  # type: ignore[call-overload] # pyright: ignore [reportArgumentType, reportCallIssue]
            del obj[k]  # type: ignore[arg-type] # pyright: ignore [reportArgumentType, reportCallIssue]
        elif (
            isinstance(host_settings, dict) and isinstance(v, (list, dict)) and (extracted := _extract_host_settings(v))
        ):
            host_settings[k] = extracted  # type: ignore[index]  # pyright: ignore [reportArgumentType, reportCallIssue]
        elif (
            isinstance(host_settings, list) and isinstance(v, (list, dict)) and (extracted := _extract_host_settings(v))
        ):
            host_settings.append(extracted)

    return host_settings  # type: ignore[return-value]  # pyright: ignore [reportGeneralTypeIssues]


def noctalia_config(*, settings_path: Path, host_settings_path: Path) -> None:
    state_raw = run_shell(["noctalia-shell", "ipc", "call", "state", "all"], capture_output=True).stdout
    state = json.loads(state_raw)
    settings = state["settings"]
    _normalize_values(settings)
    host_settings = _extract_host_settings(settings)

    # Do not enforce dark/light mode.
    del settings["colorSchemes"]["darkMode"]
    # In theory we should also do the same for color scheme,
    # but that makes color scheme reset to default after reload.
    # -- del settings["colorSchemes"]["predefinedScheme"]

    settings_path.parent.mkdir(parents=True, exist_ok=True)
    settings_path.write_text(json.dumps(settings, indent=2, sort_keys=True))

    host_settings_dump = json.dumps(host_settings, indent=2, sort_keys=True)
    header = "# This file is auto-generated. Do not edit.\n"
    host_settings_nix = header
    host_settings_nix += run_shell(
        ["nix", "eval", "--expr", f"builtins.fromJSON ''{host_settings_dump}''", "--pretty"],
        capture_output=True,
        loglevel=logging.DEBUG,
    ).stdout
    host_settings_path.parent.mkdir(parents=True, exist_ok=True)
    host_settings_path.write_text(host_settings_nix)
