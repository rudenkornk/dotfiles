local M = {}

M.opts = {
  server = {
    default_settings = {
      ["rust-analyzer"] = {
        -- Defining `check` suppresses rustaceanvim's automatic clippy configuration.
        check = {
          command = "clippy",
          extraArgs = { "--no-deps" },
          workspace = false, -- Whole-workspace checks made Neovim laggy in large Rust projects.
        },
      },
    },
  },
}

return M
