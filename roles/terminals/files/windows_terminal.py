#!/usr/bin/env python3

import difflib
import json
import logging
import os
import shutil
import subprocess
from pathlib import Path
from typing import Any

from lupa import LuaRuntime  # type: ignore

lua = LuaRuntime(unpack_returned_tuples=True)

_logger = logging.getLogger(__name__)


def _get_lua_table(theme_path: Path) -> Any:
    func_begin = """\
    function()
    vim = { opt = { bg = {} } }
    """
    func_end = """\
    end
    """
    theme_code = theme_path.read_text(encoding="UTF-8")
    theme_code = func_begin + theme_code + func_end
    lua_func = lua.eval(theme_code)
    lua_table = lua_func()
    return lua_table


def _get_win_theme(theme_path: Path) -> dict[str, str]:
    windows_terminal_map = {
        "background": "black",
        "black": "black",
        "blue": "blue",
        "brightBlack": "grey",
        "brightBlue": "nord_blue",
        "brightCyan": "cyan",
        "brightGreen": "vibrant_green",
        "brightPurple": "purple",
        "brightRed": "baby_pink",
        "brightWhite": "white",
        "brightYellow": "sun",
        "cursorColor": "white",
        "cyan": "teal",
        "foreground": "white",
        "green": "green",
        "purple": "dark_purple",
        "red": "red",
        "selectionBackground": "one_bg3",
        "white": "light_grey",
        "yellow": "yellow",
    }
    lua_table = _get_lua_table(theme_path)
    win_theme = {}
    for win, nvchad in windows_terminal_map.items():
        win_theme[win] = lua_table.base_30[nvchad].upper()
    name = theme_path.stem
    name = name.replace("_", " ")
    name = name.replace("-", " ")
    name = name.title()
    win_theme["name"] = name
    win_theme = dict(sorted(win_theme.items()))
    return win_theme


def _get_win_themes() -> list[dict[str, str]]:
    themes_path = Path.home() / ".local/share/nvim/lazy/base46/lua/base46/themes/"
    cwd = Path.cwd()
    try:
        os.chdir(Path(__file__).parent)
        win_themes = []
        for theme in themes_path.glob("*.lua"):
            win_theme = _get_win_theme(theme)
            win_themes.append(win_theme)
        win_themes = sorted(win_themes, key=lambda x: x["name"])
    finally:
        os.chdir(cwd)
    return win_themes


def _get_settings() -> dict[str, Any]:
    return {
        "actions": [
            {"command": "unbound", "keys": "ctrl+c"},
            {"command": "unbound", "keys": "ctrl+v"},
            {"command": {"action": "splitPane", "split": "auto", "splitMode": "duplicate"}, "keys": "alt+shift+d"},
            {"command": {"action": "copy", "singleLine": False}, "keys": "ctrl+alt+c"},
            {"command": "paste", "keys": "ctrl+alt+v"},
            {"command": "find", "keys": "ctrl+shift+f"},
            {"command": {"action": "openSettings", "target": "settingsUI"}, "keys": "ctrl+alt+s"},
            {"command": "toggleFocusMode", "keys": "ctrl+alt+f"},
            {"command": {"action": "closeTab"}, "keys": "ctrl+alt+w"},
        ],
        "copyOnSelect": False,
        "launchMode": "maximizedFocus",
        "profiles": {
            "defaults": {
                "altGrAliasing": False,
                "font": {"face": "FiraCode Nerd Font Mono Retina", "size": 12},
                "historySize": 100000,
                "opacity": 100,
                "padding": "0",
                "useAcrylic": False,
                "useAtlasEngine": True,
            }
        },
        "schemes": _get_win_themes(),
    }


def _update_list(lst: list[dict[str, Any]], vals: list[dict[str, Any]], id: str) -> None:
    keys = {key[id]: i for i, key in enumerate(lst)}
    for val in vals:
        if val[id] in keys:
            lst[keys[val[id]]] = val
        else:
            lst.append(val)


def update_settings(settings: dict[str, Any]) -> None:
    _logger.info("Collecting new settings...")
    new_settings = _get_settings()
    _logger.info(f"Custom actions: {len(new_settings['actions'])}")
    _logger.info(f"Custom schemes: {len(new_settings['schemes'])}")
    _update_list(settings["actions"], new_settings["actions"], "keys")
    _update_list(settings["schemes"], new_settings["schemes"], "name")
    settings["profiles"]["defaults"].update(new_settings["profiles"]["defaults"])
    settings["launchMode"] = new_settings["launchMode"]
    settings["copyOnSelect"] = new_settings["copyOnSelect"]


def _backup_path(path: Path) -> Path:
    i = 0
    while True:
        backup_path = path.with_suffix(f".bak_{i}")
        if not backup_path.exists():
            return backup_path
        i += 1


def update_config() -> None:
    _logger.info("Reading WSL vars...")
    win_profile = subprocess.run(["wslvar", "USERPROFILE"], check=True, capture_output=True, text=True).stdout.strip()
    win_home = Path(subprocess.run(["wslpath", win_profile], check=True, capture_output=True, text=True).stdout.strip())
    settings_path = win_home / "AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
    settings = json.loads(settings_path.read_text())
    original = json.dumps(settings, indent=2)
    update_settings(settings)
    updated = json.dumps(settings, indent=2)
    diff = difflib.unified_diff(original.splitlines(), updated.splitlines(), lineterm="")
    _logger.debug("Settings difference:")
    _logger.debug("\n".join(diff))

    backup_path = _backup_path(settings_path)
    _logger.info(f"Backing up old settings to {backup_path}...")
    shutil.copy(settings_path, backup_path)
    _logger.info("Writing new settings...")
    with open(settings_path, "w", encoding="UTF-8") as json_file:
        json_file.write(updated)


if __name__ == "__main__":
    logging.basicConfig(format="%(message)s", level=logging.DEBUG)
    update_config()
