-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- keymap setup
vim.opt.keymap = "rnk-qwerty-jcuken"
vim.opt.iminsert = 0
vim.opt.imsearch = -1

vim.g.autoformat = false

-- Setup ansible filetype
vim.filetype.add({
  pattern = {
    [".*/roles/.*.yaml"] = "yaml.ansible",
    ["inventory.yaml"] = "yaml.ansible",
    ["playbook.*.yaml"] = "yaml.ansible",
  },
})

vim.g.python3_host_prog = vim.fn.expand("$HOME/.venv/bin/python3")
