-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- keymap setup
vim.opt.keymap = "rnk-qwerty-jcuken"
vim.opt.iminsert = 0
vim.opt.imsearch = -1

vim.g.autoformat = true
vim.g.snacks_animate = false

vim.opt.relativenumber = false
vim.wo.wrap = true

-- Setup ansible filetype
vim.filetype.add({
  pattern = {
    [".*/roles/.*.yaml"] = "yaml.ansible",
    ["inventory.yaml"] = "yaml.ansible",
    ["playbook.*.yaml"] = "yaml.ansible",
  },
})
