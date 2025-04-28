local M = {}

-- https://github.com/folke/snacks.nvim/discussions/1802
-- https://github.com/aserowy/tmux.nvim/issues/133
-- https://github.com/folke/snacks.nvim/issues/1350
-- https://github.com/folke/snacks.nvim/discussions/1332

local function is_snacks_explorer()
  if not Snacks then
    return false
  end
  local is_explorer = vim.iter(Snacks.picker.get({ source = "explorer" })):any(function(picker)
    return picker:is_focused()
  end)
  return is_explorer
end
local function is_nvim_float()
  if is_snacks_explorer() then
    return false
  end
  return require("tmux.wrapper.nvim").is_nvim_float_original()
end
local function is_nvim_border(border)
  if is_snacks_explorer() and border == "h" then
    return true
  end
  return require("tmux.wrapper.nvim").is_nvim_border_original(border)
end

M.config = function(opts)
  require("tmux").setup(opts)

  local tmux_nvim = require("tmux.wrapper.nvim")

  tmux_nvim.is_nvim_float_original = tmux_nvim.is_nvim_float
  tmux_nvim.is_nvim_float = is_nvim_float
  tmux_nvim.is_nvim_border_original = tmux_nvim.is_nvim_border
  tmux_nvim.is_nvim_border = is_nvim_border
end

M.opts = {
  navigation = {
    enable_default_keybindings = false,
  },
  resize = {
    enable_default_keybindings = false,
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
      require("tmux").resize_left(20)
    end,
    desc = "Resize window to the left",
    mode = { "c", "n", "t", "v", "i" },
  },
  {
    "<A-x>j",
    function()
      require("tmux").resize_bottom(20)
    end,
    desc = "Resize window to the bottom",
    mode = { "c", "n", "t", "v", "i" },
  },
  {
    "<A-x>k",
    function()
      require("tmux").resize_top(20)
    end,
    desc = "Resize window to the top",
    mode = { "c", "n", "t", "v", "i" },
  },
  {
    "<A-x>l",
    function()
      require("tmux").resize_right(20)
    end,
    desc = "Resize window to the right",
    mode = { "c", "n", "t", "v", "i" },
  },
  {
    "<A-x><S-h>",
    function()
      require("tmux").resize_left(1)
    end,
    desc = "Resize window to the left",
    mode = { "c", "n", "t", "v", "i" },
  },
  {
    "<A-x><S-j>",
    function()
      require("tmux").resize_bottom(1)
    end,
    desc = "Resize window to the bottom",
    mode = { "c", "n", "t", "v", "i" },
  },
  {
    "<A-x><S-k>",
    function()
      require("tmux").resize_top(1)
    end,
    desc = "Resize window to the top",
    mode = { "c", "n", "t", "v", "i" },
  },
  {
    "<A-x><S-l>",
    function()
      require("tmux").resize_right(1)
    end,
    desc = "Resize window to the right",
    mode = { "c", "n", "t", "v", "i" },
  },
}

return M
