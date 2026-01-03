local M = {}

M.keys = {
  {
    "<leader>aa",
    function()
      local tools = { default = "copilot", corp = "qwen" }
      require("sidekick.cli").toggle({ name = tools[os.getenv("USERKIND")] })
    end,
    desc = "Sidekick Toggle CLI",
  },
}

return M
