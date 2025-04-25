local M = {}

M.opts = {
  picker = {
    hidden = true,
    ignored = true,
    actions = {
      list_scroll_down_4 = function(picker)
        picker.list:scroll(4, false)
      end,
      list_scroll_up_4 = function(picker)
        picker.list:scroll(-4, false)
      end,
      win_right = function(picker)
        vim.api.nvim_command("wincmd l")
      end,
    },
    sources = {
      -- https://github.com/folke/snacks.nvim/discussions/1802
      -- https://github.com/aserowy/tmux.nvim/issues/133
      -- https://github.com/folke/snacks.nvim/issues/1350
      -- https://github.com/folke/snacks.nvim/discussions/1332
      explorer = {
        win = {
          input = {
            keys = {
              ["<C-l>"] = { "win_right", mode = { "i", "n" } }, -- W/A for tmux navigation
            },
          },
          list = {
            keys = {
              ["<C-l>"] = { "win_right", mode = { "i", "n" } }, -- W/A for tmux navigation
            },
          },
        },
      },
    },
    win = {
      input = {
        keys = {
          ["<C-j>"] = false, -- disable, conflicts with tmux navigation
          ["<C-k>"] = false, -- disable, conflicts with tmux navigation
          ["<C-y>"] = { "list_scroll_up_4", mode = { "i", "n" } },
          ["<C-e>"] = { "list_scroll_down_4", mode = { "i", "n" } },
        },
      },
      list = {
        keys = {
          ["<C-j>"] = false, -- disable, conflicts with tmux navigation
          ["<C-k>"] = false, -- disable, conflicts with tmux navigation
          ["<C-y>"] = { "list_scroll_up_4", mode = { "i", "n" } },
          ["<C-e>"] = { "list_scroll_down_4", mode = { "i", "n" } },
        },
      },
    },
  },
}

return M
