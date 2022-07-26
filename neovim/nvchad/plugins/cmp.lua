return {
  sources = {
    { name = "luasnip" },
    { name = "nvim_lsp" },
    { name = "buffer" },
    { name = "nvim_lua" },
    { name = "path" },
    { name = "rg" },
    {
      name = "tmux",
      option = {
        all_panes = false,
        label = "[tmux]",
        trigger_characters = { "." },
        trigger_characters_ft = {}, -- { filetype = { '.' } }
      },
    },
  },
}
