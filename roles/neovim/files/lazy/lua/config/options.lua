-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- keymap setup
vim.opt.keymap = "rnk-qwerty-jcuken"
vim.opt.iminsert = 0
vim.opt.imsearch = -1

-- Disable auto-formatting, since it really messes up with 3rd party codebase
-- with its own different (or absent) formatting rules.
-- https://github.com/LazyVim/LazyVim/blob/25abbf546d564dc484cf903804661ba12de45507/lua/lazyvim/config/options.lua#L6
vim.g.autoformat = false

-- All animations work poorly on my setup for some reason
-- https://github.com/LazyVim/LazyVim/blob/25abbf546d564dc484cf903804661ba12de45507/lua/lazyvim/config/options.lua#L10
vim.g.snacks_animate = false

-- Relative line numbers is a cool feature, but I do not like it for two reasons:
-- 1. It introduces constantly changing ribbon on the side, which is distracting.
-- 2. It prevents from quickly find a desired line if search by line number.
--    This happens often when debugging linter errors from CLI invocations.
vim.opt.relativenumber = false

-- Why is this not a default?
-- https://github.com/LazyVim/LazyVim/blob/25abbf546d564dc484cf903804661ba12de45507/lua/lazyvim/config/options.lua#L112
vim.wo.wrap = true

-- Setup ansible filetype
vim.filetype.add({
  pattern = {
    [".*/roles/.*.yaml"] = "yaml.ansible",
    ["inventory.yaml"] = "yaml.ansible",
    ["playbook.*.yaml"] = "yaml.ansible",
  },
})

-- mitigate the long clipboard loading issue
vim.g.clipboard = require("config.clipboard")
