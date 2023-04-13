local M = {}

M.mappings = require("custom.mappings")
M.plugins = "custom.plugins"
M.ui = require("custom.ui")
M.lazy_nvim = {
  lockfile = vim.fn.stdpath("config") .. "/lua/custom" .. "/lazy-lock.json",
}

-- Keep themes here instead of "ui" module in order to support NvChad's interactive theme picker
M.ui.theme = "bearded-arc"
M.ui.theme_toggle = { M.ui.theme, "catppuccin_latte" }

return M
