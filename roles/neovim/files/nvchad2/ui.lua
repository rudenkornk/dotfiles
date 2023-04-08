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
    overriden_modules = function()
      local st_modules = require("nvchad_ui.statusline.default")
      local paste_status = ""
      if vim.o.paste then
        paste_status = "%#St_file_info# paste"
      end
      local lang = "%#St_file_info#"
      if vim.o.iminsert == 1 then
        lang = lang .. "ru"
      else
        lang = lang .. "en"
      end
      return {
        mode = function()
          return st_modules.mode() .. lang .. paste_status
        end,
        cursor_position = function()
          local total = vim.fn.line("$")
          local total_len = math.floor(math.log10(total)+1)
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          local row_format = "%" .. total_len .. "s"
          row = string.format(row_format, row)
          col = string.format("%3s", col)
          local line = row .. "/" .. total .. " " .. col .. ""
          local nvchad_fmt = st_modules.cursor_position()
          local nvchad_no_percent = string.sub(nvchad_fmt, 1, string.len(nvchad_fmt) - 5)
          return nvchad_no_percent .. line
        end,
      }
    end,
    separator_style = "round"
  },
  tabufline = {
    enabled = true,
    lazyload = true,
  },
}
