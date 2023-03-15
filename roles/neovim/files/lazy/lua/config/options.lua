-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

-- keymap setup
opt.keymap = "rnk-qwerty-jcuken"
opt.iminsert = 0
opt.imsearch = -1

vim.g.clipboard = require("config.clipboard")
