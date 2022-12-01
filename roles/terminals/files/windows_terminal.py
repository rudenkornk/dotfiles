#!/usr/bin/env python3

from lupa import LuaRuntime
from pathlib import Path
import json
import os
import subprocess

lua = LuaRuntime(unpack_returned_tuples=True)


def get_lua_table(theme_path: Path):
    func_begin = """\
    function()
    vim = { opt = { bg = {} } }
    """
    func_end = """\
    end
    """
    with open(theme_path, "r") as f:
        theme_code = f.read()
    theme_code = func_begin + theme_code + func_end
    lua_func = lua.eval(theme_code)
    lua_table = lua_func()
    return lua_table


def get_win_theme(theme_path: Path):
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
    lua_table = get_lua_table(theme_path)
    win_theme = dict()
    for win, nvchad in windows_terminal_map.items():
        win_theme[win] = lua_table.base_30[nvchad].upper()
    name = theme_path.stem
    name = name.replace("_", " ")
    name = name.replace("-", " ")
    name = name.title()
    win_theme["name"] = name
    win_theme = dict(sorted(win_theme.items()))
    return win_theme


def get_win_themes():
    themes_path = Path.home() / ".local/share/nvim/site/pack/packer/start/base46/lua/base46/themes/"
    win_themes = []
    for theme in themes_path.glob("*.lua"):
        win_theme = get_win_theme(theme)
        win_themes.append(win_theme)
    win_themes = sorted(win_themes, key=lambda x: x["name"])
    return win_themes


# Not implemented
def write_win_themes(win_themes):
    win_profile = subprocess.run(["wslvar", "USERPROFILE"], check=True, capture_output=True)
    win_profile = win_profile.stdout.decode().strip()
    win_home = subprocess.run(["wslpath", win_profile], check=True, capture_output=True)
    win_home = Path(win_home.stdout.decode().strip())
    settings_path = win_home / "AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
    settings = json.loads(settings_path.read_text())


if __name__ == "__main__":
    os.chdir(Path(__file__).parent)
    win_themes = get_win_themes()
    print(json.dumps(win_themes, indent=4))
