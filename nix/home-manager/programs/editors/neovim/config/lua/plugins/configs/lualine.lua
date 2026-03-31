local M = {}

M.opts = function(_, opts)
  table.insert(opts.sections.lualine_a, {
    function()
      if vim.o.iminsert == 1 then
        return "ru"
      else
        return "en"
      end
    end,
  })
  -- Assign cursor position to the last segment.
  -- Previously last segment displayed datetime, which is redundant in `tmux` context.
  opts.sections.lualine_z = opts.sections.lualine_y
  opts.sections.lualine_y = {}
end

return M
