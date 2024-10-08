-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set(
  { "n", "x" },
  "<C-z>",
  function() end,
  { silent = true, desc = "Service keymap to disable neovim suspension" }
)
vim.keymap.set({ "n", "x" }, "<C-e>", "4<C-e>", { silent = true, desc = "Scroll up" })
vim.keymap.set({ "n", "x" }, "<C-y>", "4<C-y>", { silent = true, desc = "Scroll down" })
vim.keymap.set({ "x" }, "<leader>vs", ":sort i<CR>", { desc = "Sort selected lines" })
vim.keymap.set({ "n" }, "<C-q>", "a<C-^><ESC>", { desc = "Toggle keyboard layout" })

vim.keymap.set({ "n" }, "<A-m>", function()
  LazyVim.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })
vim.keymap.set({ "t" }, "<A-m>", "<cmd>close<cr>", { desc = "Close terminal" })

vim.keymap.set({ "i" }, "<C-q>", "<C-^>", { desc = "Toggle keyboard layout" })
