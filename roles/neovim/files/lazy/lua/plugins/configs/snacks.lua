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

local function add_terminal_key(keys_table, key, position, width)
  table.insert(keys_table, {
    key,
    function()
      Snacks.terminal(nil, {
        win = { position = position, width = width },
        -- Snacks identifies terminal by combination of cmd, cwd and env.
        -- The first terminal opened with a given combination (id), will stick to all
        -- other keys, even if they dictate other win position.
        -- https://github.com/folke/snacks.nvim/blob/main/docs/terminal.md#snacksterminalget
        -- Thus, we need to provide uninque env for each terminal.
        env = { __dummy_nvim_var_for_term_id = position },
      })
    end,
    -- Do not add "v" mode: it might conflict with other keymaps
    mode = { "i", "n", "t" },
    desc = "Toggle terminal (" .. position .. ")",
  })
end

M.keys = {
  {
    "<S-q>",
    function()
      Snacks.bufdelete()
    end,
    { desc = "Delete current buffer" },
  },
}

add_terminal_key(M.keys, "<A-f>", "float", 0.9)
add_terminal_key(M.keys, "<C-_>", "right", 0.4)
add_terminal_key(M.keys, "<A-L>", "right", 0.4)
add_terminal_key(M.keys, "<A-H>", "left", 0.4)
add_terminal_key(M.keys, "<A-J>", "bottom", 0.5)
add_terminal_key(M.keys, "<A-K>", "top", 0.5)

return M
