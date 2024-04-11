-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_autocmd("VimLeave", {
  pattern = "*",
  command = "set guicursor=a:ver10",
})

vim.api.nvim_create_autocmd("SwapExists", {
  pattern = "*",
  command = "let v:swapchoice = 'o'",
})

vim.api.nvim_del_augroup_by_name("lazyvim_highlight_yank")

-- This should be inside options.lua, but for some reason it doesn't work there
-- Probably some plugin overwrites it later
vim.g.clipboard = require("config.clipboard")
