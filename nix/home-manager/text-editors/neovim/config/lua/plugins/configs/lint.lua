local M = {}

M.opts = {
  linters = {
    -- Adapted for parent-root validation and child-module diagnostic paths.
    -- Upstream issues:
    -- https://codeberg.org/mfussenegger/nvim-lint/issues/18
    -- https://github.com/mfussenegger/nvim-lint/issues/885
    --
    -- The code is adapted from:
    -- https://github.com/mfussenegger/nvim-lint/blob/dfc71303bbee/lua/lint/linters/terraform_validate.lua
    terraform_validate = function()
      local filename = vim.api.nvim_buf_get_name(0)
      local root = vim.fs.root(filename, { ".terraform.lock.hcl", ".terraform" }) or vim.fs.dirname(filename)
      local severities = {
        error = vim.diagnostic.severity.ERROR,
        warning = vim.diagnostic.severity.WARN,
        notice = vim.diagnostic.severity.INFO,
      }

      return {
        cmd = "terraform",
        cwd = root,
        args = { "validate", "-json" },
        append_fname = false,
        stdin = false,
        stream = "stdout",
        ignore_exitcode = true,
        parser = function(output, bufnr)
          local diagnostics = {}
          local buffer_path = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
          for _, diagnostic in ipairs(vim.json.decode(output).diagnostics or {}) do
            local range = diagnostic.range
            local path = range and vim.fs.normalize(vim.fs.joinpath(root, range.filename))
            if not range or path == buffer_path then
              table.insert(diagnostics, {
                message = diagnostic.summary .. (diagnostic.detail and " - " .. diagnostic.detail or ""),
                source = "terraform validate",
                severity = severities[diagnostic.severity],
                lnum = range and range.start.line - 1 or 0,
                col = range and range.start.column - 1 or 0,
                end_lnum = range and range["end"].line - 1 or nil,
                end_col = range and range["end"].column - 1 or nil,
              })
            end
          end
          return diagnostics
        end,
      }
    end,
  },
}

return M
