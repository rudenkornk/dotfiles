local M = {}

M.opts = {
  linters_by_ft = {
    python = { "pylint", "mypy" },
  },
  linters = {
    pylint = {
      cmd = "python3",
      args = { "-m", "pylint", "-f", "json" },
    },
    mypy = {
      cmd = "python3",
      args = {
        "-m",
        "mypy",
        "--show-column-numbers",
        "--show-error-end",
        "--hide-error-codes",
        "--hide-error-context",
        "--no-color-output",
        "--no-error-summary",
        "--no-pretty",
      },
    },
  },
}

return M
