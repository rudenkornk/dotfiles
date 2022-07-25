return {
  module = "illuminate",
  config = function()
    -- does not work :(
    vim.g.Illuminate_highlightUnderCursor = 0
    local autocmd = vim.api.nvim_create_autocmd
    autocmd("VimEnter", {
      pattern = "*",
      command = "hi illuminatedWord cterm=underline gui=underline",
    })
  end,
}
