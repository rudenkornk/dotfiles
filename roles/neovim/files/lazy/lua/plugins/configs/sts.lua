local M = {}

M.keys = {
  {
    "<A-j>",
    function()
      vim.opt.opfunc = "v:lua.STSSwapDownNormal_Dot"
      return "g@l"
    end,
    desc = "Move syntax node down",
    expr = true,
    mode = { "n" },
  },
  {
    "<A-k>",
    function()
      vim.opt.opfunc = "v:lua.STSSwapUpNormal_Dot"
      return "g@l"
    end,
    desc = "Move syntax node up",
    expr = true,
    mode = { "n" },
  },
}

return M
