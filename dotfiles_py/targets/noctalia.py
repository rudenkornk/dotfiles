import json
import logging
from pathlib import Path
from typing import Any

from ..utils import run_shell

_logger = logging.getLogger(__name__)


_home = str(Path.home())


def _replace_home(obj: dict[str, Any] | list[Any]) -> None:
    iter_obj = obj.items() if isinstance(obj, dict) else enumerate(obj)
    for k, v in iter_obj:
        if isinstance(v, str) and v.startswith(_home):
            obj[k] = "~" + v.removeprefix(_home)  # type: ignore[index]  # pyright: ignore [reportArgumentType, reportCallIssue]
        elif isinstance(v, (dict, list)):
            _replace_home(v)


def _extract_monitors[T: list[Any] | dict[str, Any]](obj: T) -> T:
    res = type(obj)()
    iter_obj = obj.copy().items() if isinstance(obj, dict) else enumerate(obj.copy())
    for k, v in iter_obj:
        if k in ("monitors", "lockScreenMonitors"):
            res[k] = v  # type: ignore[index] # pyright: ignore [reportArgumentType, reportCallIssue]
            del obj[k]  # type: ignore[arg-type] # pyright: ignore [reportArgumentType, reportCallIssue]
        elif isinstance(res, dict) and isinstance(v, (list, dict)) and (extracted := _extract_monitors(v)):
            res[k] = extracted  # type: ignore[index]  # pyright: ignore [reportArgumentType, reportCallIssue]
        elif isinstance(res, list) and isinstance(v, (list, dict)) and (extracted := _extract_monitors(v)):
            res.append(extracted)

    return res  # type: ignore[return-value]  # pyright: ignore [reportGeneralTypeIssues]


def noctalia_config(*, settings_path: Path, monitor_settings_path: Path) -> None:
    state_raw = run_shell(["noctalia-shell", "ipc", "call", "state", "all"], capture_output=True).stdout
    state = json.loads(state_raw)
    settings = state["settings"]
    _replace_home(settings)
    monitors = _extract_monitors(settings)

    settings_path.parent.mkdir(parents=True, exist_ok=True)
    settings_path.write_text(json.dumps(settings, indent=2, sort_keys=True))

    monitors_dump = json.dumps(monitors, indent=2, sort_keys=True)
    monitors_nix = run_shell(
        ["nix", "eval", "--expr", f"builtins.fromJSON ''{monitors_dump}''", "--pretty"],
        capture_output=True,
        loglevel=logging.DEBUG,
    ).stdout
    monitor_settings_path.parent.mkdir(parents=True, exist_ok=True)
    monitor_settings_path.write_text(monitors_nix)
