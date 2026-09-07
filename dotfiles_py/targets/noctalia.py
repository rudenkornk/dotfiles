import logging
import tomllib
from pathlib import Path
from typing import Any

import tomli_w

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


def _extract_host_settings(settings: dict[str, Any]) -> dict[str, Any]:
    host_settings: dict[str, Any] = {}
    if "device" in settings.get("battery", {}):
        host_settings["battery"] = {"device": settings["battery"].pop("device")}
    for section in ("dock", "lockscreen", "notification", "osd"):
        if "monitors" in settings.get(section, {}):
            host_settings[section] = {"monitors": settings[section].pop("monitors")}
    if "lockscreen_widgets" in settings:
        host_settings["lockscreen_widgets"] = settings.pop("lockscreen_widgets")
    for name, bar in settings.get("bar", {}).items():
        if "monitor" in bar:
            host_settings.setdefault("bar", {})[name] = {"monitor": bar.pop("monitor")}
    if "monitor" in settings.get("brightness", {}):
        host_settings["brightness"] = {"monitor": settings["brightness"].pop("monitor")}
    return host_settings


def _remove_irrelevant_settings(settings: dict[str, Any]) -> None:
    for key in ("default", "last", "monitors"):
        settings.get("wallpaper", {}).pop(key, None)


def _remove_secret_settings(settings: dict[str, Any]) -> None:
    wallhaven = settings.get("plugin_settings", {}).get("noctalia/wallhaven", {})
    wallhaven.pop("api_key", None)


def noctalia_config(*, settings_path: Path, host_settings_path: Path) -> None:
    settings_raw = run_shell(["noctalia", "config", "export"], capture_output=True).stdout
    settings = tomllib.loads(settings_raw)
    _remove_irrelevant_settings(settings)
    _remove_secret_settings(settings)
    _normalize_values(settings)
    host_settings = _extract_host_settings(settings)

    settings_path.parent.mkdir(parents=True, exist_ok=True)
    settings_path.write_text(
        tomli_w.dumps({"include": {"autoload": False, "files": ["host.toml", "secrets.toml"]}, **settings})
    )

    header = "# This file is auto-generated. Do not edit.\n"
    host_settings_path.parent.mkdir(parents=True, exist_ok=True)
    host_settings_path.write_text(header + tomli_w.dumps(host_settings))
