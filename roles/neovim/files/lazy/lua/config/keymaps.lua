-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- <C-a> -- increment
-- <C-b> -- scroll back page
-- <C-c> -- ???
-- <C-d> -- scroll down half page
-- <C-e> -- scroll up lines
-- <C-f> -- scroll down page
-- <C-g> -- ???
-- <C-h> -- pane navigation
-- <C-i> -- go forward
-- <C-j> -- pane navigation
-- <C-k> -- pane navigation
-- <C-l> -- pane navigation
-- <C-m> -- open terminal
-- <C-n> -- ???
-- <C-o> -- go back
-- <C-p> -- ???
-- <C-q> -- change input lang
-- <C-r> -- redo
-- <C-s> -- tmux reserved
-- <C-t> -- ???
-- <C-u> -- scroll up half page
-- <C-v> -- visual mode
-- <C-w> -- manage windows
-- <C-x> -- decrement
-- <C-y> -- scroll down lines
-- <C-z> -- ???

-- <S-a> -- insert at the end of line
-- <S-b> -- word back
-- <S-c> -- replace rest of line
-- <S-d> -- delete rest of line
-- <S-e> -- word end
-- <S-f> -- find prev symbol
-- <S-g> -- end of file
-- <S-h> -- prev buffer
-- <S-i> -- insert at the beginning of line
-- <S-j> -- delete newline
-- <S-k> -- symbol info
-- <S-l> -- next buffer
-- <S-m> --
-- <S-n> --
-- <S-o> -- open line above
-- <S-p> -- paste before cursor
-- <S-q> -- delete buffer (custom)
-- <S-r> -- replace sequence
-- <S-s> -- leap back
-- <S-t> -- find prev symbol
-- <S-u> --
-- <S-v> -- visual select line
-- <S-w> -- word forward
-- <S-x> --
-- <S-y> -- yy
-- <S-z> --

-- <A-a> --
-- <A-b> --
-- <A-c> -- dap continue
-- <A-d> -- dap down
-- <A-e> -- dap pause
-- <A-f> --
-- <A-g> -- dap restart
-- <A-h> -- dedent code
-- <A-i> -- dap step into
-- <A-j> -- move code down
-- <A-k> -- move code up
-- <A-l> -- move code right
-- <A-m> -- open terminal
-- <A-n> -- next reference
-- <A-o> -- dap step out
-- <A-p> -- previous reference
-- <A-q> --
-- <A-r> -- dap breakpoint
-- <A-s> --
-- <A-t> --
-- <A-u> -- dap up
-- <A-v> -- dap run to cursor
-- <A-w> --
-- <A-x> -- tmux reserved
-- <A-y> --
-- <A-z> --

-- <A-C> -- dap reverse continue
-- <A-R> -- dap breakpoint with condition

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
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })
vim.keymap.set({ "t" }, "<A-m>", "<cmd>close<cr>", { desc = "Close terminal" })

vim.keymap.set({ "i" }, "<C-q>", "<C-^>", { desc = "Toggle keyboard layout" })
vim.keymap.set({ "n" }, "<S-q>", function()
  Snacks.bufdelete()
end, { desc = "Delete current buffer" })

-- mitigate the long clipboard loading issue
vim.g.clipboard = require("config.clipboard")
