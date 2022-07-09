return {
  statusline = {
    overriden_modules = function()
      local st_modules = require "nvchad_ui.statusline.modules"
      local paste_status = ""
      if vim.o.paste then
         paste_status = "%#St_file_info#PASTE"
      end
      return {
         mode = function ()
            return st_modules.mode() .. paste_status
         end
      }
    end,
  },
  tabufline = {
    disable = true,
  }
}
