local M = {}

M.opts = function()
  local per_filetype = {}

  for _, ft in ipairs({
    "html",
    "xml",
    "javascriptreact",
    "typescriptreact",
    "vue",
    "svelte",
    "astro",
    "htmlangular",
    "heex",
    "templ",
  }) do
    per_filetype[ft] = {
      enable_close = true,
      enable_rename = true,
    }
  end

  return {
    opts = {
      enable_close = false,
      enable_rename = false,
      enable_close_on_slash = false,
    },
    per_filetype = per_filetype,
  }
end

return M
