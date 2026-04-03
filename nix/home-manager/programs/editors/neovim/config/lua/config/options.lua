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

-- Detect root only using .git
-- `LazyVim` defaults for `<leader><space>` find files and `<leader>/` live grep open in a  "root" directory.
-- This `root` directory has a rather complicated algorithm, which does not work for me well
-- in cases with nested projects inside one repo:
--    It correctly detects the root of each sub-project,
--    whereas I, being a simple man, just want to use the root of the whole repo.
-- See:
-- https://github.com/LazyVim/LazyVim/blob/25abbf546d564dc484cf903804661ba12de45507/lua/lazyvim/config/options.lua#L33
-- https://github.com/LazyVim/LazyVim/blob/25abbf546d564dc484cf903804661ba12de45507/lua/lazyvim/util/root.lua
-- https://github.com/LazyVim/lazyvim.github.io/blob/5cc96146d96bb61ad915088bc3eec4151643cd6f/docs/news.md?plain=1#L258
vim.g.root_spec = { ".git", "cwd" }
