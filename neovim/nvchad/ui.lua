local themes = {
  ["dark"] = "onedark",
  ["light"] = "one_light",
}
local kind = "dark"
local theme_name = themes[kind]

local colors = {
  ["dark"] = {
    illuminate = {
      fg = "cyan",
      bg = "one_bg2",
    },
    spaces = {
      bg = "grey",
    },
    copilot = {
      fg = "blue",
    },
  },
  ["light"] = {
    illuminate = {
      fg = "cyan",
      bg = "one_bg2",
    },
    spaces = {
      bg = "yellow",
    },
    copilot = {
      fg = "blue",
    },
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
    RedundantSpacesAndTabs = get_colors("spaces"),
    CmpItemKindCopilot = get_colors("copilot"),
  },
  transparency = false,
}
