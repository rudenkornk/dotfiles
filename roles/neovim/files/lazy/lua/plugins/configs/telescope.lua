local M = {}

M.opts = function(_, opts)
  local actions = require("telescope.actions")

  opts.defaults.scroll_strategy = "limit"
  opts.extension_list = { "undo" }
  opts.defaults.mappings = {
    i = {
      ["<C-f>"] = actions.results_scrolling_down,
      ["<C-b>"] = actions.results_scrolling_up,
    },
  }
end

return M
