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
      supermaven = {
        score_offset = 10,
      },
      copilot = {
        score_offset = 10,
      },
    },
  },
  completion = {
    list = {
      -- For some reason enabled auto_insert suddenly closes the completion menu,
      -- after pressed down "select_next/select_prev" keymaps for ~1000ms.
      selection = { auto_insert = false },
      cycle = { from_bottom = false, from_top = false },
    },
    documentation = { auto_show_delay_ms = 0 },
  },
  keymap = {
    ["<C-k>"] = { "show", "show_documentation", "hide_documentation" },
    ["<C-d>"] = {
      function(cmp)
        for _ = 1, 5 do
          cmp.select_next()
        end
      end,
    },
    ["<C-u>"] = {
      function(cmp)
        for _ = 1, 5 do
          cmp.select_prev()
        end
      end,
    },
  },
}

return M
