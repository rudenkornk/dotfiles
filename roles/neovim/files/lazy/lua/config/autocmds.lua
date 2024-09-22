-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Set cursor to vertical bar when leaving vim
vim.api.nvim_create_autocmd("VimLeave", {
  pattern = "*",
  command = "set guicursor=a:ver10",
})

-- Do not warn when opening same file in another neovim instance
vim.api.nvim_create_autocmd("SwapExists", {
  pattern = "*",
  command = "let v:swapchoice = 'o'",
})

vim.api.nvim_del_augroup_by_name("lazyvim_highlight_yank")
