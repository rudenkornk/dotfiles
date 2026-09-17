local M = {}

M.keys = {
  {
    "<leader>uu",
    function()
      require("duck").hatch(nil, 1)
    end,
    mode = { "n" },
    desc = "Hatch a duck",
  },
  {
    "<leader>uU",
    function()
      require("duck").cook()
    end,
    mode = { "n" },
    desc = "Cook all ducks",
  },
}

return M
