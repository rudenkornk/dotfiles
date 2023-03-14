local config = function()
  require("neoscroll").setup({
    easing_function = "cubic",
  })
  local mappings = {}
  -- Syntax: t[keys] = {function, {function arguments}}
  mappings["<C-u>"] = { "scroll", { "-vim.wo.scroll", "true", "50" } }
  mappings["<C-d>"] = { "scroll", { "vim.wo.scroll", "true", "50" } }
  mappings["<C-b>"] = { "scroll", { "-vim.api.nvim_win_get_height(0)", "true", "75" } }
  mappings["<C-f>"] = { "scroll", { "vim.api.nvim_win_get_height(0)", "true", "75" } }
  mappings["<C-y>"] = { "scroll", { "-0.10", "false", "50" } }
  mappings["<C-e>"] = { "scroll", { "0.10", "false", "50" } }
  mappings["zt"] = { "zt", { "50" } }
  mappings["zz"] = { "zz", { "50" } }
  mappings["zb"] = { "zb", { "50" } }

  require("neoscroll.config").set_mappings(mappings)
end

return config
