local M = {}
local manifest = require("custom.plugins.manifest")

M.commit = manifest["williamboman/mason.nvim"].commit

M.override_options = {
  ensure_installed = {
    "actionlint",
    "alex",
    "ansible-language-server",
    "ansible-lint",
    "arduino-language-server",
    "autopep8",
    "awk-language-server",
    "bash-debug-adapter",
    "bash-language-server",
    "beautysh",
    "black",
    "cbfmt",
    "clang-format",
    "clangd",
    "cmake-language-server",
    "cmakelang",
    "codespell",
    "commitlint",
    "css-lsp",
    "docker-compose-language-service",
    "dockerfile-language-server",
    "dot-language-server",
    "editorconfig-checker",
    "eslint_d",
    "flake8",
    "fortls",
    "gersemi",
    "gitlint",
    "gofumpt",
    "goimports",
    "goimports-reviser",
    "golangci-lint-langserver",
    "gopls",
    "groovy-language-server",
    "hadolint",
    "html-lsp",
    "isort",
    "jdtls",
    "jedi-language-server",
    "jq",
    "jq-lsp",
    "json-lsp",
    "jsonlint",
    "kotlin-language-server",
    "ktlint",
    "latexindent",
    "lua-language-server",
    "luacheck",
    "markdownlint",
    "marksman",
    "mypy",
    "neocmakelsp",
    "opencl-language-server",
    "perlnavigator",
    "puppet-editor-services",
    "pydocstyle",
    "pylint",
    "python-lsp-server",
    "rubocop",
    "ruby-lsp",
    "rust-analyzer",
    "rustfmt",
    "salt-lsp",
    "shellcheck",
    "shfmt",
    "sql-formatter",
    "sqlfluff",
    "sqlls",
    "stylua",
    "texlab",
    "verible",
    "vim-language-server",
    "write-good",
    "yaml-language-server",
    "yamlfmt",
    "yamllint",
    -- "asm-lsp", -- not working
    -- "csharp-language-server", -- dotnet required
    -- "csharpier", -- dotnet required
    -- "haskell-language-server", -- haskel required
    -- "luaformatter", -- using stylua instead; also takes a lot of time to install
    -- "ocaml-lsp", -- ocaml required
    -- "ocamlformat", -- ocaml required
    -- "powershell-editor-services", -- not working
    -- "r-languageserver", - R required
  },
}

return M
