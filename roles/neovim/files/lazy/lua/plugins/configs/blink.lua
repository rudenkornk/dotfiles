local M = {}

M.dependencies = {
  "andersevenrud/cmp-tmux",
  "hrsh7th/cmp-emoji",
}
M.opts = {
  sources = {
    compat = { "emoji", "tmux" },
    providers = {
      tmux = {
        name = "tmux",
        score_offset = -50,
        opts = { label = " ", all_panes = true },
      },
    },
  },
}

return M
