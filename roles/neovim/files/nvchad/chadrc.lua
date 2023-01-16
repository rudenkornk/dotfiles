local M = {}

M.mappings = require("custom.mappings")
M.plugins = require("custom.plugins")
M.ui = require("custom.ui")

-- Keep themes here instead of "ui" module in order to support NvChad's interactive theme picker
M.ui.theme = "chadracula"
M.ui.theme_toggle = { M.ui.theme, "catppuccin_latte" }

return M
