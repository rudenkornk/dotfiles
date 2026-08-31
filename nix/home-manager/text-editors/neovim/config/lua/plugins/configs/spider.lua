local M = {}

M.opts = {
  consistentOperatorPending = true,
}

M.keys = {
  -- Keep Ex commands because Lua callbacks do not preserve dot-repeat.
  { "w", "<cmd>lua require('spider').motion('w')<cr>", mode = { "n", "o", "x" }, desc = "Next Subword" },
  { "e", "<cmd>lua require('spider').motion('e')<cr>", mode = { "n", "o", "x" }, desc = "Next Subword End" },
  { "b", "<cmd>lua require('spider').motion('b')<cr>", mode = { "n", "o", "x" }, desc = "Previous Subword" },
  { "ge", "<cmd>lua require('spider').motion('ge')<cr>", mode = { "n", "o", "x" }, desc = "Previous Subword End" },
}

return M
