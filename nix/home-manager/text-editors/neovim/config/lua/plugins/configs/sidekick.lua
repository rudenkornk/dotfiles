local M = {}

M.opts = {
  nes = {
    enabled = true,
  },
}

M.keys = {
  {
    "<leader>aa",
    function()
      require("sidekick.cli").toggle({ name = "opencode" })
    end,
    desc = "Sidekick Toggle CLI",
  },
}

return M
