local M = {}

M.keys = {
  {
    "<A-j>",
    function()
      vim.opt.opfunc = "v:lua.STSSwapDownNormal_Dot"
      return "g@l"
    end,
    expr = true,
    mode = { "n" },
  },
  {
    "<A-k>",
    function()
      vim.opt.opfunc = "v:lua.STSSwapUpNormal_Dot"
      return "g@l"
    end,
    expr = true,
    mode = { "n" },
  },
  {
    "<A-l>",
    function()
      vim.opt.opfunc = "v:lua.STSSwapCurrentNodeNextNormal_Dot"
      return "g@l"
    end,
    expr = true,
    mode = { "n" },
  },
  {
    "<A-h>",
    function()
      vim.opt.opfunc = "v:lua.STSSwapCurrentNodePrevNormal_Dot"
      return "g@l"
    end,
    expr = true,
    mode = { "n" },
  },
}

return M
