-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set({ "n", "x" }, "<C-z>", function() end, { silent = true }) -- disable suspend
vim.keymap.set({ "n", "x" }, "<C-e>", "4<C-e>", { silent = true })
vim.keymap.set({ "n", "x" }, "<C-y>", "4<C-y>", { silent = true })
vim.keymap.set({ "x" }, "<leader>vs", ":sort i<CR>")
vim.keymap.set({ "n" }, "<C-q>", "a<C-^><ESC>") -- toggle layout
vim.keymap.set({ "i" }, "<C-q>", "<C-^>") -- toggle layout
