local M = {}

M.opts = {
  consistentOperatorPending = false,
  skipInsignificantPunctuation = false,
}

M.keys = {
  -- Keep Ex commands because Lua callbacks do not preserve dot-repeat.
  { "w", "<cmd>lua require('spider').motion('w')<cr>", mode = { "n", "o", "x" }, desc = "Next subword" },
  { "e", "<cmd>lua require('spider').motion('e')<cr>", mode = { "n", "o", "x" }, desc = "Next subword end" },
  { "b", "<cmd>lua require('spider').motion('b')<cr>", mode = { "n", "o", "x" }, desc = "Previous subword" },
  { "ge", "<cmd>lua require('spider').motion('ge')<cr>", mode = { "n", "o", "x" }, desc = "Previous subword end" },

  { "cw", "c<cmd>lua require('spider').motion('e')<cr>", mode = { "n" }, desc = "Change subword" },
}

return M
