local M = {}

M.config = function(_, opts)
  LazyVim.mini.pairs(opts)
  require("mini.pairs").map("i", ">", {
    action = "close",
    pair = "<>",
    register = { bs = false, cr = false },
  })
end

return M
