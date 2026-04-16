local M = {}

M.opts = {
  navigation = {
    enable_default_keybindings = false,
  },
  resize = {
    enable_default_keybindings = false,
  },
}

local function tmux_move(direction, key)
  return {
    key,
    function()
      require("tmux").move_to(direction)
    end,
    desc = "Move cursor to the " .. direction .. " window",
    mode = { "c", "n", "t", "v", "i" },
  }
end

local function tmux_resize(direction, key, size)
  return {
    key,
    function()
      require("tmux").resize_to(direction, size)
    end,
    desc = "Resize window to the " .. direction .. " by " .. size,
    mode = { "c", "n", "t", "v", "i" },
  }
end

M.keys = {
  tmux_move("h", "<C-h>"),
  tmux_move("l", "<C-l>"),
  tmux_move("j", "<C-j>"),
  tmux_move("k", "<C-k>"),
  tmux_resize("h", "<A-z>h", 15),
  tmux_resize("l", "<A-z>l", 15),
  tmux_resize("j", "<A-z>j", 10),
  tmux_resize("k", "<A-z>k", 10),
  tmux_resize("h", "<A-z><S-h>", 1),
  tmux_resize("l", "<A-z><S-l>", 1),
  tmux_resize("j", "<A-z><S-j>", 1),
  tmux_resize("k", "<A-z><S-k>", 1),
}

return M
