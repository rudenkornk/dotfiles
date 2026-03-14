local M = {}

M.opts = {
  -- TODO: remove this section entirely once modules support in clangd becomes stable.
  servers = {
    clangd = {
      -- See https://www.lazyvim.org/extras/lang/clangd
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--function-arg-placeholders",
        "--fallback-style=llvm",
        "--experimental-modules-support",
      },
    },
  },
}

return M
