-- Support russian with specific keyboard layouts
vim.o.keymap = "rnk-qwerty-jcuken"
vim.o.iminsert = 0
vim.o.imsearch = -1
vim.o.scrolloff = 2

vim.g.fileignorecase = true

vim.api.nvim_create_autocmd("VimLeave", {
  pattern = "*",
  command = "set guicursor=a:ver10",
})

vim.g.nobackup = true
vim.g.nowritebackup = true

vim.g.notimeout = true
vim.g.nottimeout = true
vim.opt.timeoutlen = 10000000

vim.g.clipboard = require("custom.clipboard")

-- Setup gdb
vim.cmd([[ packadd termdebug ]])
vim.g.termdebug_wide = 163

vim.cmd([[ match RedundantSpacesAndTabs /\(\s\+$\|\t\+\)/ ]])
