local M = {}

M.dependencies = {
  "Saghen/blink.compat",
  "andersevenrud/cmp-tmux",
  "hrsh7th/cmp-emoji",
  "Kaiser-Yang/blink-cmp-avante",
}
M.opts = {
  sources = {
    compat = { "emoji", "tmux" },
    default = {
      "lsp",
      "path",
      "snippets",
      "buffer",
      "avante",
    },
    providers = {
      tmux = {
        name = "tmux",
        score_offset = -50,
        opts = { label = " ", all_panes = true },
      },
      avante = {
        name = "avante",
        module = "blink-cmp-avante",
      },
      supermaven = {
        score_offset = 15,
      },
      copilot = {
        score_offset = 14,
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
