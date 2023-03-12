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

-- see https://www.reddit.com/r/neovim/comments/ab01n8/improve_neovim_startup_by_60ms_for_free_on_macos/
-- and https://www.reddit.com/r/neovim/comments/wb2obw/how_to_setup_gclipboard_using_lua/
local clipboards = {
  ["win32yank"] = {
    name = "win32yank",
    copy = {
      ["+"] = { "win32yank.exe", "-i", "--crlf" },
      ["*"] = { "win32yank.exe", "-i", "--crlf" },
    },
    paste = {
      ["+"] = { "win32yank.exe", "-o", "--lf" },
      ["*"] = { "win32yank.exe", "-o", "--lf" },
    },
    cache_enabled = true,
  },
  ["xsel"] = {
    name = "xsel",
    copy = {
      ["+"] = { "xsel", "--nodetach", "-i", "-b" },
      ["*"] = { "xsel", "--nodetach", "-i", "-p" },
    },
    paste = {
      ["+"] = { "xsel", "-o", "-b" },
      ["*"] = { "xsel", "-o", "-p" },
    },
    cache_enabled = true,
  },
}
local clipboard = require("custom.clipboard")

vim.g.clipboard = clipboards[clipboard]

-- Setup gdb
vim.cmd([[ packadd termdebug ]])
vim.g.termdebug_wide = 163

vim.cmd([[ match RedundantSpacesAndTabs /\(\s\+$\|\t\+\)/ ]])
