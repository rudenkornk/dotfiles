local M = {}

M.opts = {
  navigation = {
    enable_default_keybindings = false,
  },
  resize = {
    enable_default_keybindings = false,
    resize_step_x = 5,
    resize_step_y = 5,
  },
}

M.keys = {
  {
    "<C-h>",
    function()
      require("tmux").move_left()
    end,
    desc = "Move cursor to the left window",
    mode = { "c", "n", "t", "v", "i" },
  },
  {
    "<C-j>",
    function()
      require("tmux").move_bottom()
    end,
    desc = "Move cursor to the bottom window",
    mode = { "c", "n", "t", "v", "i" },
  },
  {
    "<C-k>",
    function()
      require("tmux").move_top()
    end,
    desc = "Move cursor to the top window",
    mode = { "c", "n", "t", "v", "i" },
  },
  {
    "<C-l>",
    function()
      require("tmux").move_right()
    end,
    desc = "Move cursor to the right window",
    mode = { "c", "n", "t", "v", "i" },
  },
  {
    "<A-x>h",
    function()
      require("tmux").resize_left()
    end,
    desc = "Resize window to the left",
    mode = { "c", "n", "t", "v", "i" },
  },
  {
    "<A-x>j",
    function()
      require("tmux").resize_bottom()
    end,
    desc = "Resize window to the bottom",
    mode = { "c", "n", "t", "v", "i" },
  },
  {
    "<A-x>k",
    function()
      require("tmux").resize_top()
    end,
    desc = "Resize window to the top",
    mode = { "c", "n", "t", "v", "i" },
  },
  {
    "<A-x>l",
    function()
      require("tmux").resize_right()
    end,
    desc = "Resize window to the right",
    mode = { "c", "n", "t", "v", "i" },
  },
}

return M
