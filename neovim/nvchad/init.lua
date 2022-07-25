-- Support russian with specific keyboard layouts
vim.o.keymap = "rnk-russian-qwerty"
vim.o.iminsert = 0
vim.o.imsearch = -1

vim.g.fileignorecase = true
vim.cmd([[
augroup dynamic_smartcase
    autocmd!
    autocmd CmdLineEnter : set nosmartcase
    autocmd CmdLineLeave : set smartcase
augroup END
]])

vim.g.nobackup = true
vim.g.nowritebackup = true

-- Setup gdb
vim.cmd([[ packadd termdebug ]])
vim.g.termdebug_wide = 163

vim.cmd([[ set nrformats+=alpha ]])
vim.cmd([[ highlight RedundantSpacesAndTabs ctermbg=100 guibg=#b5942e ]])
vim.cmd([[ match RedundantSpacesAndTabs /\(\s\+$\|\t\+\)/ ]])

-- load your globals, autocmds here or anything .__.
