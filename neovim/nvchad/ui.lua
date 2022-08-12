local themes = {
  dark = "chadracula",
  light = "catppuccin_latte",
}
local kind = "dark"
local theme_name = themes[kind]

return {
  theme = theme_name,
  theme_toggle = { themes.dark, themes.light },
  hl_override = {
    LspReferenceRead = { fg = "cyan", bg = "one_bg2" },
    LspReferenceText = { fg = "cyan", bg = "one_bg2" },
    LspReferenceWrite = { fg = "cyan", bg = "one_bg2" },
  },
  hl_add = {
    CmpItemMenuBuffer = { link = "CmpItemKindText" },
    CmpItemMenuCmdLine = { link = "CmpItemKindVariable" },
    CmpItemMenuCopilot = { fg = "blue" },
    CmpItemMenuGit = { link = "CmpItemKindText" },
    CmpItemMenuLSP = { link = "CmpItemKindFunction" },
    CmpItemMenuLuasnip = { link = "CmpItemKindSnippet" },
    CmpItemMenuNeovimLua = { link = "CmpItemKindFunction" },
    CmpItemMenuPath = { fg = "CmpItemKindFolder" },
    CmpItemMenuRipGrep = { link = "CmpItemKindText" },
    CmpItemMenuTabnine = { fg = "dark_purple" },
    CmpItemMenuTmux = { link = "CmpItemKindText" },
    FocusedSymbol = {},
    RedundantSpacesAndTabs = { bg = "grey" },
  },
}
