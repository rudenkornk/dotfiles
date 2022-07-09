local dark_theme = "onedark"
local light_theme = "one_light"
local theme = dark_theme

local illuminate_colors = {
  ["onedark"] = {
    fg = "cyan",
    bg = "lightbg",
  },
}

return {
  theme = theme,
  theme_toggle = { dark_theme, light_theme },
  hl_override = {
    LspReferenceText = illuminate_colors[theme],
    LspReferenceWrite = illuminate_colors[theme],
    LspReferenceRead = illuminate_colors[theme],
  },
  transparency = false,
}
