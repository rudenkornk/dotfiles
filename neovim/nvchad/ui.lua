local themes = {
  ["dark"] = "onedark",
  ["light"] = "one_light",
}
local kind = "dark"
local theme_name = themes[kind]

local colors = {
  dark = {
    copilot_cmp = { fg = "blue" },
    illuminate = { fg = "cyan", bg = "one_bg2" },
    spaces = { bg = "grey" },
  },
  light = {
    copilot_cmp = { fg = "blue" },
    illuminate = { fg = "cyan", bg = "one_bg2" },
    spaces = { bg = "yellow" },
  },
}

local function get_colors(component)
  return colors[theme_name] and colors[theme_name][component] or colors[kind][component]
end


return {
  theme = theme_name,
  theme_toggle = { themes.dark, themes.light },
  hl_override = {
    LspReferenceRead = get_colors("illuminate"),
    LspReferenceText = get_colors("illuminate"),
    LspReferenceWrite = get_colors("illuminate"),
  },
  hl_add = {
    CmpItemMenuCopilot = get_colors("copilot_cmp"),
    RedundantSpacesAndTabs = get_colors("spaces"),
  },
  transparency = false,
}
