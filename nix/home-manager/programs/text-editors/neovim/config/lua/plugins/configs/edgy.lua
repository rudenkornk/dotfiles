local M = {}

M.opts = {
  animate = { enabled = false },
  keys = {
    ["<A-x>h"] = function(win)
      win:resize("width", 20)
    end,
    ["<A-x>l"] = function(win)
      win:resize("width", -20)
    end,
    ["<A-x>j"] = function(win)
      win:resize("height", 20)
    end,
    ["<A-x>k"] = function(win)
      win:resize("height", -20)
    end,
    ["<A-x><S-h>"] = function(win)
      win:resize("width", 1)
    end,
    ["<A-x><S-l>"] = function(win)
      win:resize("width", -1)
    end,
    ["<A-x><S-j>"] = function(win)
      win:resize("height", 1)
    end,
    ["<A-x><S-k>"] = function(win)
      win:resize("height", -1)
    end,
  },
}

return M
