-- Support russian with specific keyboard layouts
vim.o.keymap = "rnk-russian-qwerty"
vim.o.iminsert = 0
vim.o.imsearch = -1

vim.g.fileignorecase = true

vim.api.nvim_create_autocmd("VimLeave", {
  pattern = "*",
  command = "set guicursor=a:ver10",
})

vim.g.nobackup = true
vim.g.nowritebackup = true

vim.g.notimeout = true
vim.g.nottimeout = true

-- Setup gdb
vim.cmd([[ packadd termdebug ]])
vim.g.termdebug_wide = 163

vim.cmd([[ set nrformats+=alpha ]])
vim.cmd([[ match RedundantSpacesAndTabs /\(\s\+$\|\t\+\)/ ]])

-- load your globals, autocmds here or anything .__.
