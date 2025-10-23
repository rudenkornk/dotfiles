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

M.config = function(_, opts)
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

local function tmux_move(direction, key)
  return {
    key,
    function()
      local tmux = require("tmux")
      if direction == "left" then
        tmux.move_left()
      elseif direction == "right" then
        tmux.move_right()
      elseif direction == "bottom" then
        tmux.move_bottom()
      elseif direction == "top" then
        tmux.move_top()
      end
    end,
    desc = "Move cursor to the " .. direction .. " window",
    mode = { "c", "n", "t", "v", "i" },
  }
end

local function tmux_resize(direction, key, size)
  return {
    key,
    function()
      local tmux = require("tmux")
      if direction == "left" then
        tmux.resize_left(size)
      elseif direction == "right" then
        tmux.resize_right(size)
      elseif direction == "bottom" then
        tmux.resize_bottom(size)
      elseif direction == "top" then
        tmux.resize_top(size)
      end
    end,
    desc = "Resize window to the " .. direction .. " by " .. size,
    mode = { "c", "n", "t", "v", "i" },
  }
end

M.keys = {
  tmux_move("left", "<C-h>"),
  tmux_move("right", "<C-l>"),
  tmux_move("bottom", "<C-j>"),
  tmux_move("top", "<C-k>"),
  tmux_resize("left", "<A-x>h", 15),
  tmux_resize("right", "<A-x>l", 15),
  tmux_resize("bottom", "<A-x>j", 10),
  tmux_resize("top", "<A-x>k", 10),
  tmux_resize("left", "<A-x><S-h>", 1),
  tmux_resize("right", "<A-x><S-l>", 1),
  tmux_resize("bottom", "<A-x><S-j>", 1),
  tmux_resize("top", "<A-x><S-k>", 1),
}

return M
