return {
  hl_override = {
    LspReferenceRead = { fg = "cyan", bg = "one_bg2" },
    LspReferenceText = { fg = "cyan", bg = "one_bg2" },
    LspReferenceWrite = { fg = "cyan", bg = "one_bg2" },
  },
  hl_add = {
    CmpItemMenuAI = { link = "CmpItemKindFunction" },
    CmpItemMenuBuffer = { link = "CmpItemKindText" },
    CmpItemMenuCmdLine = { link = "CmpItemKindVariable" },
    CmpItemMenuCopilot = { fg = "blue" },
    CmpItemMenuGit = { link = "CmpItemKindText" },
    CmpItemMenuLSP = { link = "CmpItemKindFunction" },
    CmpItemMenuEmoji = { fg = "orange" },
    CmpItemMenuLuasnip = { link = "CmpItemKindSnippet" },
    CmpItemMenuNeovimLua = { link = "CmpItemKindFunction" },
    CmpItemMenuPath = { fg = "CmpItemKindFolder" },
    CmpItemMenuRipGrep = { link = "CmpItemKindText" },
    CmpItemMenuTabnine = { fg = "dark_purple" },
    CmpItemMenuTmux = { link = "CmpItemKindText" },
    FocusedSymbol = {},
    RedundantSpacesAndTabs = { bg = "grey" },
  },
  statusline = {
    separator_style = "round"
  },
  tabufline = {
    enabled = true,
    lazyload = true,
  },
}
