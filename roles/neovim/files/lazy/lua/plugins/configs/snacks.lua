local M = {}

local function filter_colorscheme(entry)
  -- Filter out original vim themes
  if entry.file:find(vim.env.VIMRUNTIME .. "/colors", 1, true) then
    return false
  end
  -- Filter out light themes
  local light = { "light", "day", "latte", "rose-pine-dawn", "kanagawa-lotus" }
  for _, ending in ipairs(light) do
    if entry.text:sub(-#ending) == ending then
      return false
    end
  end
  return true
end

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
      colorschemes = {
        -- Amend list of colorschemes by excluding original vim themes and light themes
        -- See https://github.com/LazyVim/LazyVim/discussions/6032#discussioncomment-13031344
        finder = function()
          local items = require("snacks.picker.source.vim").colorschemes()
          return vim.tbl_filter(filter_colorscheme, items)
        end,
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
    formatters = {
      file = {
        truncate = 150,
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
    desc = "Delete current buffer",
  },
  {
    "<C-g>",
    function()
      Snacks.lazygit()
    end,
    mode = { "i", "n" },
    desc = "Lazygit",
  },
}

add_terminal_key(M.keys, "<A-F>", "float", 0.9)
add_terminal_key(M.keys, "<C-_>", "right", 0.4)
add_terminal_key(M.keys, "<A-L>", "right", 0.4)
add_terminal_key(M.keys, "<A-H>", "left", 0.4)
add_terminal_key(M.keys, "<A-J>", "bottom", 0.5)
add_terminal_key(M.keys, "<A-K>", "top", 0.5)

return M
