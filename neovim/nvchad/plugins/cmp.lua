return {
  sources = {
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
