return function()
  local null_ls = require("null-ls")
  local code_actions = null_ls.builtins.code_actions
  local diagnostics = null_ls.builtins.diagnostics
  local formatting = null_ls.builtins.formatting

  local sources = {
    -- generic
    diagnostics.codespell,
    -- diagnostics.write_good,
    formatting.codespell,

    -- Ansible
    diagnostics.ansiblelint,

    -- C++
    formatting.clang_format,

    -- CMake
    diagnostics.cmake_lint,
    -- formatting.cmake_format, -- already included in cmake lsp
    -- formatting.gersemi, -- alternative (do not forget do disable formatting in lsp)

    -- dockerfile
    diagnostics.hadolint,

    -- .editorconfig
    diagnostics.editorconfig_checker,

    -- fish
    diagnostics.fish,
    formatting.fish_indent,

    -- git
    code_actions.gitsigns,
    diagnostics.gitlint,
    -- diagnostics.commitlint,

    -- go
    formatting.gofumpt,
    formatting.goimports,
    formatting.goimports_reviser,

    -- groovy
    formatting.npm_groovy_lint,

    -- GitHub Actions
    diagnostics.actionlint,

    -- javascript
    code_actions.eslint_d,
    diagnostics.eslint_d,
    formatting.eslint_d,

    -- json
    diagnostics.jsonlint,
    formatting.jq,

    -- latex
    formatting.bibclean,
    formatting.latexindent.with({
      args = { "--logfile=build/latexindent.log", "--local", "--lines '.a:firstline.'-'.a:lastline.'" },
    }),

    -- lua
    diagnostics.luacheck,
    formatting.stylua,
    -- formatting.lua_format, -- using stylua instead

    -- markdown
    diagnostics.alex,
    -- diagnostics.markdownlint,
    formatting.cbfmt,
    formatting.markdownlint,

    -- python
    diagnostics.mypy,
    diagnostics.pydocstyle,
    diagnostics.pylint,
    formatting.autopep8,
    formatting.black,
    formatting.isort,
    -- diagnostics.flake8, -- using black instead

    -- ruby
    diagnostics.rubocop,
    formatting.rubocop,

    -- rust
    formatting.rustfmt,

    -- shell
    code_actions.shellcheck,
    diagnostics.shellcheck.with({ diagnostics_format = "#{m} [#{c}]" }),
    formatting.beautysh,
    formatting.shfmt,

    -- yaml
    diagnostics.yamllint,
    formatting.yamlfmt,

    -- verilog
    formatting.verible_verilog_format,
  }
  return {
    sources = sources,
    debug = false,
  }
end
