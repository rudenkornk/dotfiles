local M = {}

M.opts = {
  checkbox = {
    enabled = true,
    -- `bullet = true` and `right_pad = 2` makes line same width rendered and unrendered.
    bullet = true,
    right_pad = 2,
  },
  -- Prevent rendered and normal versions to be different in lines,
  -- which makes document "flicker" when switching between them.
  code = { border = "thick" },
  pipe_table = { style = "normal" },
  link = { enabled = false },
  win_options = { conceallevel = { default = 0, rendered = 0 } },

  file_types = { "markdown", "Avante" },
}

M.ft = { "markdown", "Avante" }

return M
