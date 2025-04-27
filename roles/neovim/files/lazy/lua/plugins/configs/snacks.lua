local M = {}

M.opts = {
  picker = {
    hidden = true,
    sources = {
      explorer = {
        ignored = true,
      },
      files = {
        -- For some reason, upper-level "hidden" opt is not picked up here
        hidden = true,
      },
    },
    actions = {
      list_scroll_down_4 = function(picker)
        picker.list:scroll(4, false)
      end,
      list_scroll_up_4 = function(picker)
        picker.list:scroll(-4, false)
      end,
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
