local M = {}

-- Disable next edit suggestions. They need the `copilot-language-server`, which we do not install,
-- and we rely on `minuet-ai` and the AI CLI tools instead.
-- With `nes.enabled = false`, `LazyVim`'s `ai.sidekick` extra also stops registering the copilot LSP.
M.opts = {
  nes = {
    enabled = false,
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
