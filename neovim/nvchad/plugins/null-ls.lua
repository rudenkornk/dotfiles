return {
  after = "nvim-lspconfig",
  config = function()
    local null_ls = require("null-ls")

    local sources = {
      -- C++
      null_ls.builtins.formatting.clang_format,

      -- CMake
      null_ls.builtins.formatting.cmake_format,

      -- dockerfile
      null_ls.builtins.diagnostics.hadolint,

      -- fish
      null_ls.builtins.diagnostics.fish,
      null_ls.builtins.formatting.fish_indent,

      -- git
      null_ls.builtins.code_actions.gitsigns,

      -- groovy
      null_ls.builtins.formatting.npm_groovy_lint,

      -- GitHub Actions
      null_ls.builtins.diagnostics.actionlint,

      -- javascript
      null_ls.builtins.code_actions.eslint_d,
      null_ls.builtins.diagnostics.eslint_d,
      null_ls.builtins.formatting.eslint_d,

      -- latex
      null_ls.builtins.formatting.bibclean,
      null_ls.builtins.formatting.latexindent.with({
        args = { "--logfile=build/latexindent.log", "--local", "--lines '.a:firstline.'-'.a:lastline.'" },
      }),

      -- lua
      null_ls.builtins.formatting.stylua,

      -- markdown
      null_ls.builtins.diagnostics.alex,

      -- python
      null_ls.builtins.diagnostics.flake8,
      null_ls.builtins.formatting.autopep8,

      -- shell
      null_ls.builtins.code_actions.shellcheck,
      null_ls.builtins.formatting.shfmt,
      null_ls.builtins.diagnostics.shellcheck.with({ diagnostics_format = "#{m} [#{c}]" }),
    }
    null_ls.setup({
      sources = sources,
      debug = false,
    })
  end,
}
