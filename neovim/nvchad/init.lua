-- Support russian with specific keyboard layouts
vim.o.keymap = "rnk-russian-qwerty"
vim.o.iminsert = 0
vim.o.imsearch = -1

-- Disable formatting in insert mode
-- Unfortunatelly this breaks autocomplete with tab, so it is not permanently
-- enabled
-- vim.cmd([[ set paste ]])
-- Instead use pastetoggle workaround
vim.o.pastetoggle = "<C-q>"

--vim.cmd([[ set wildmode=longest:list,full ]])

vim.g.nobackup = true
vim.g.nowritebackup = true

-- Setup gdb
vim.cmd([[ packadd termdebug ]])
vim.g.termdebug_wide = 163

vim.cmd([[ set nrformats+=alpha ]])
vim.cmd([[ highlight RedundantSpacesAndTabs ctermbg=100 guibg=#b5942e ]])
vim.cmd([[ match RedundantSpacesAndTabs /\(\s\+$\|\t\+\)/ ]])

-- load your globals, autocmds here or anything .__.
