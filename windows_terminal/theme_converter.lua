local home = os.getenv("HOME")
local themes_path = home .. "/.local/share/nvim/site/pack/packer/start/base46/lua/base46/themes/"
local themes_pattern = themes_path .. "/?.lua"
package.path = package.path .. ";" .. themes_pattern
vim = { opt = { bg = {} } }

local function convert_to_windows_terminal(name, theme)
  local windows_terminal_map = {
    background = "black",
    selectionBackground = "one_bg3",
    foreground = "white",
    cursorColor = "white",
    black = "black",
    brightBlack = "grey",
    white = "light_grey",
    brightWhite = "white",
    blue = "blue",
    brightBlue = "nord_blue",
    cyan = "teal",
    brightCyan = "cyan",
    green = "green",
    brightGreen = "vibrant_green",
    purple = "dark_purple",
    brightPurple = "purple",
    red = "red",
    brightRed = "baby_pink",
    yellow = "yellow",
    brightYellow = "sun",
  }
  local win_name = name:gsub("^%l", string.upper)
  local win_theme = {}
  win_theme.name = win_name
  for win, nvchad in pairs(windows_terminal_map) do
    win_theme[win] = string.upper(theme.base_30[nvchad])
  end
  return win_theme
end

local function get_theme_names()
  local theme_names = {}
  local lfs_ = require("lfs")
  for file in lfs_.dir(themes_path) do
    local mode = lfs_.attributes(file, "mode") or ""
    if mode ~= "directory" then
      local name = string.sub(file, 1, -5)
      table.insert(theme_names, name)
    end
  end
  return theme_names
end

local function get_windows_terminal_themes(theme_names)
  local win_themes = {}
  for _, name in pairs(theme_names) do
    local theme = require(name)
    local win_theme = convert_to_windows_terminal(name, theme)
    table.insert(win_themes, win_theme)
  end
  return win_themes
end

local json = require("json")
print(json.encode(get_windows_terminal_themes(get_theme_names())))

