return {
  statusline = {
    overriden_modules = function()
      local st_modules = require "nvchad_ui.statusline.modules"
      local paste_status = ""
      if vim.o.paste then
         paste_status = "%#St_file_info# paste"
      end
      local lang = "%#St_file_info#"
      if vim.o.iminsert==1 then
        lang = lang .. "ru"
      else
        lang = lang .. "en"
      end
      return {
         mode = function ()
            return st_modules.mode() .. lang .. paste_status
         end
      }
    end,
  },
  tabufline = {
    disable = true,
  }
}
