local M = {}
local manifest = require("custom.plugins.manifest")

M.commit = manifest["williamboman/mason.nvim"].commit

M.override_options = {
  ensure_installed = {
    "actionlint",
    "alex",
    "ansible-language-server",
    "arduino-language-server",
    "autopep8",
    "awk-language-server",
    "bash-language-server",
    "beautysh",
    "black",
    "clang-format",
    "clangd",
    "cmake-language-server",
    "cmakelang",
    "css-lsp",
    "dockerfile-language-server",
    "dot-language-server",
    "editorconfig-checker",
    "eslint_d",
    "flake8",
    "gitlint",
    "groovy-language-server",
    "hadolint",
    "html-lsp",
    "jedi-language-server",
    "json-lsp",
    "lua-language-server",
    "markdownlint",
    "opencl-language-server",
    "perlnavigator",
    -- "powershell-editor-services", -- not working
    "puppet-editor-services",
    "python-lsp-server",
    "rubocop",
    "ruby-lsp",
    "rust-analyzer",
    "rustfmt",
    "salt-lsp",
    "shellcheck",
    "shfmt",
    "sqlls",
    "stylua",
    "texlab",
    "vim-language-server",
    "write-good",
    "yaml-language-server",
    "yamlfmt",
    "yamllint",
    -- "asm-lsp", -- not working
  },
}

return M
