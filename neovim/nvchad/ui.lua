local themes = {
  ["dark"] = "radium",
  ["light"] = "catppuccin_latte",
}
local kind = "dark"
local theme_name = themes[kind]

local colors = {
  dark = {
    buffer_cmp = { fg = "green" },
    cmdline_cmp = { fg = "purple" },
    copilot_cmp = { fg = "blue" },
    focused_symbol = {},
    git_cmp = { fg = "green" },
    illuminate = { fg = "cyan", bg = "one_bg2" },
    lsp_cmp = { fg = "yellow" },
    luasnip_cmp = { fg = "red" },
    nvim_lua_cmp = { fg = "yellow" },
    path_cmp = { fg = "white" },
    rg_cmp = { fg = "green" },
    spaces = { bg = "grey" },
    tabnine_cmp = { fg = "dark_purple" },
    tmux_tmp = { fg = "green" },
  },
  light = {
    buffer_cmp = { fg = "green" },
    cmdline_cmp = { fg = "purple" },
    copilot_cmp = { fg = "blue" },
    focused_symbol = {},
    git_cmp = { fg = "green" },
    illuminate = { fg = "cyan", bg = "one_bg2" },
    lsp_cmp = { fg = "yellow" },
    luasnip_cmp = { fg = "red" },
    nvim_lua_cmp = { fg = "yellow" },
    path_cmp = { fg = "white" },
    rg_cmp = { fg = "green" },
    spaces = { bg = "grey" },
    tabnine_cmp = { fg = "dark_purple" },
    tmux_tmp = { fg = "green" },
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
    FocusedSymbol = get_colors("focused_symbol"),
    CmpItemMenuBuffer = get_colors("buffer_cmp"),
    CmpItemMenuCmdLine = get_colors("cmdline_cmp"),
    CmpItemMenuCopilot = get_colors("copilot_cmp"),
    CmpItemMenuGit = get_colors("git_cmp"),
    CmpItemMenuLSP = get_colors("lsp_cmp"),
    CmpItemMenuLuasnip = get_colors("luasnip_cmp"),
    CmpItemMenuNeovimLua = get_colors("nvim_lua_cmp"),
    CmpItemMenuPath = get_colors("path_cmp"),
    CmpItemMenuRipGrep = get_colors("rg_cmp"),
    CmpItemMenuTabnine = get_colors("tabnine_cmp"),
    CmpItemMenuTmux = get_colors("tmux_tmp"),
    RedundantSpacesAndTabs = get_colors("spaces"),
  },
  transparency = false,
}
