local M = {}

M.opts = {
  sections = {
    lualine_a = {
      { "mode" },
      {
        function()
          if vim.o.iminsert == 1 then
            return "ru"
          else
            return "en"
          end
        end,
      },
    },
    lualine_z = {},
  },
}

return M
