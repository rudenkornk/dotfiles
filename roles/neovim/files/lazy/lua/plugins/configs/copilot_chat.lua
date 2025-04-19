local M = {}

M.opts = function(_, opts)
  return vim.tbl_extend("force", opts, {
    mappings = {
      reset = { normal = "<C-z>", insert = "<C-z>" },
      submit_prompt = { insert = "" },
      accept_diff = { normal = "<C-g>", insert = "<C-g>" },
    },
  })
end

return M
