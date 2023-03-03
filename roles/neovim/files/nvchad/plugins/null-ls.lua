local manifest = require("custom.plugins.manifest")

return {
  after = "nvim-lspconfig",
  commit = manifest["jose-elias-alvarez/null-ls.nvim"].commit,
  config = function()
    local null_ls = require("null-ls")

    local sources = {
      -- generic
      null_ls.builtins.diagnostics.write_good,

      -- Ansible
      null_ls.builtins.diagnostics.ansiblelint,

      -- C++
      null_ls.builtins.formatting.clang_format,

      -- CMake
      null_ls.builtins.formatting.cmake_format,
      null_ls.builtins.diagnostics.cmake_lint,

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

      -- groovy
      null_ls.builtins.formatting.npm_groovy_lint,

      -- GitHub Actions
      null_ls.builtins.diagnostics.actionlint,

      -- javascript
      null_ls.builtins.code_actions.eslint_d,
      null_ls.builtins.diagnostics.eslint_d,
      null_ls.builtins.formatting.eslint_d,

      null_ls.builtins.formatting.jq,

      -- latex
      null_ls.builtins.formatting.bibclean,
      null_ls.builtins.formatting.latexindent.with({
        args = { "--logfile=build/latexindent.log", "--local", "--lines '.a:firstline.'-'.a:lastline.'" },
      }),

      -- lua
      null_ls.builtins.formatting.stylua,

      -- markdown
      null_ls.builtins.diagnostics.alex,
      null_ls.builtins.diagnostics.markdownlint,

      -- ocaml
      null_ls.builtins.formatting.ocamlformat,

      -- python
      null_ls.builtins.diagnostics.flake8,
      null_ls.builtins.diagnostics.mypy,
      null_ls.builtins.diagnostics.pylint,
      null_ls.builtins.formatting.autopep8,
      null_ls.builtins.formatting.black,
      null_ls.builtins.formatting.isort,

      -- ruby
      null_ls.builtins.diagnostics.rubocop,

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

    }
    null_ls.setup({
      sources = sources,
      debug = false,
    })
  end,
}
