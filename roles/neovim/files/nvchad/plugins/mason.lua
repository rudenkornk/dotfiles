local M = {}
local manifest = require("custom.plugins.manifest")

M.commit = manifest["williamboman/mason.nvim"].commit

M.override_options = {
  ensure_installed = {
    "ansible-language-server",
    "bash-language-server",
    "clang-format",
    "clangd",
    "cmake-language-server",
    "cmakelang",
    "css-lsp",
    "dockerfile-language-server",
    "dot-language-server",
    "eslint_d",
    "flake8",
    "groovy-language-server",
    "hadolint",
    "html-lsp",
    "jedi-language-server",
    "json-lsp",
    "lua-language-server",
    "markdownlint",
    "opencl-language-server",
    "perlnavigator",
    "python-lsp-server",
    "shellcheck",
    "shfmt",
    "stylua",
    "texlab",
    "vim-language-server",
    "yaml-language-server",
    "yamlfmt",
    "yamllint",
  },
}

return M
