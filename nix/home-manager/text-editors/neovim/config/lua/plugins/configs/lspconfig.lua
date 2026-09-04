local M = {}

local root_detectors = require("config.root_detectors")

local function cwd_lsp_root(markers)
  return function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, markers)
    -- External definition buffers must not start an LSP server for their containing repository.
    if root and vim.fs.relpath(root_detectors.cwd_root(bufnr), root) then
      on_dir(root)
    end
  end
end

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
    pyright = {
      root_dir = cwd_lsp_root({
        "pyrightconfig.json",
        "pyproject.toml",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        "Pipfile",
        ".git",
      }),
    },
    ruff = {
      root_dir = cwd_lsp_root({ "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" }),
    },
  },
}

return M
