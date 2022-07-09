-- Support russian with specific keyboard layouts
vim.cmd([[ set keymap=rnk-russian-qwerty ]])
vim.cmd([[ set iminsert=0 ]])
vim.cmd([[ set imsearch=-1 ]])

-- Disable formatting in insert mode
-- Unfortunatelly this breaks autocomplete with tab, so it is not permanently
-- enabled
-- vim.cmd([[ set paste ]])
-- Instead use pastetoggle workaround
vim.cmd([[ set pastetoggle=<C-q> ]])

--vim.cmd([[ set wildmode=longest:list,full ]])

vim.cmd([[ set nobackup ]])
vim.cmd([[ set nowritebackup ]])

-- Setup gdb
vim.cmd([[ packadd termdebug ]])
vim.cmd([[ let g:termdebug_wide = 163 ]])

vim.cmd([[ set tabstop=2 ]])
vim.cmd([[ set expandtab ]])
vim.cmd([[ set nrformats+=alpha ]])
vim.cmd([[ highlight RedundantSpacesAndTabs ctermbg=100 guibg=#b5942e ]])
vim.cmd([[ match RedundantSpacesAndTabs /\(\s\+$\|\t\+\)/ ]])

-- load your globals, autocmds here or anything .__.
