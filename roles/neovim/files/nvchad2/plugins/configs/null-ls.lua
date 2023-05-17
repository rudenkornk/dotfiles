return function()
  local null_ls = require("null-ls")

  local sources = {
    -- generic
    null_ls.builtins.diagnostics.codespell,
    -- null_ls.builtins.diagnostics.write_good,
    null_ls.builtins.formatting.codespell,

    -- Ansible
    null_ls.builtins.diagnostics.ansiblelint,

    -- C++
    null_ls.builtins.formatting.clang_format,

    -- CMake
    null_ls.builtins.diagnostics.cmake_lint,
    -- null_ls.builtins.formatting.cmake_format, -- already included in cmake lsp
    -- null_ls.builtins.formatting.gersemi, -- alternative (do not forget do disable formatting in lsp)

    -- dockerfile
    null_ls.builtins.diagnostics.hadolint,

    -- .editorconfig
    null_ls.builtins.diagnostics.editorconfig_checker,

    -- fish
    null_ls.builtins.diagnostics.fish,
    null_ls.builtins.formatting.fish_indent,

    -- git
    null_ls.builtins.code_actions.gitsigns,
    null_ls.builtins.diagnostics.gitlint,
    -- null_ls.builtins.diagnostics.commitlint,

    -- go
    null_ls.builtins.formatting.gofumpt,
    null_ls.builtins.formatting.goimports,
    null_ls.builtins.formatting.goimports_reviser,

    -- groovy
    null_ls.builtins.formatting.npm_groovy_lint,

    -- GitHub Actions
    null_ls.builtins.diagnostics.actionlint,

    -- javascript
    null_ls.builtins.code_actions.eslint_d,
    null_ls.builtins.diagnostics.eslint_d,
    null_ls.builtins.formatting.eslint_d,

    -- json
    null_ls.builtins.diagnostics.jsonlint,
    null_ls.builtins.formatting.jq,

    -- latex
    null_ls.builtins.formatting.bibclean,
    null_ls.builtins.formatting.latexindent.with({
      args = { "--logfile=build/latexindent.log", "--local", "--lines '.a:firstline.'-'.a:lastline.'" },
    }),

    -- lua
    null_ls.builtins.diagnostics.luacheck,
    null_ls.builtins.formatting.stylua,
    -- null_ls.builtins.formatting.lua_format, -- using stylua instead

    -- markdown
    null_ls.builtins.diagnostics.alex,
    -- null_ls.builtins.diagnostics.markdownlint,
    null_ls.builtins.formatting.cbfmt,
    null_ls.builtins.formatting.markdownlint,

    -- python
    null_ls.builtins.diagnostics.mypy,
    null_ls.builtins.diagnostics.pydocstyle,
    null_ls.builtins.diagnostics.pylint,
    null_ls.builtins.formatting.autopep8,
    null_ls.builtins.formatting.black,
    null_ls.builtins.formatting.isort,
    -- null_ls.builtins.diagnostics.flake8, -- using black instead

    -- ruby
    null_ls.builtins.diagnostics.rubocop,
    null_ls.builtins.formatting.rubocop,

    -- rust
    null_ls.builtins.formatting.rustfmt,

    -- shell
    null_ls.builtins.code_actions.shellcheck,
    null_ls.builtins.diagnostics.shellcheck.with({ diagnostics_format = "#{m} [#{c}]" }),
    null_ls.builtins.formatting.beautysh,
    null_ls.builtins.formatting.shfmt,

    -- yaml
    null_ls.builtins.diagnostics.yamllint,
    null_ls.builtins.formatting.yamlfmt,

    -- verilog
    null_ls.builtins.formatting.verible_verilog_format,
  }
  return {
    sources = sources,
    debug = false,
  }
end
