return {
  cmd = {
    "SymbolsOutline",
    "SymbolsOutlineOpen",
    "SymbolsOutlineClose",
  },
  setup = function()
    vim.g.symbols_outline = {
      highlight_hovered_item = false,
    }
  end,
}
