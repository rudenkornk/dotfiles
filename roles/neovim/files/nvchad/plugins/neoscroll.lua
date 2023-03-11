local config = function()
  require("neoscroll").setup({
    easing_function = "cubic",
  })
  local mappings = {}
  -- Syntax: t[keys] = {function, {function arguments}}
  mappings["<C-u>"] = { "scroll", { "-vim.wo.scroll", "true", "100" } }
  mappings["<C-d>"] = { "scroll", { "vim.wo.scroll", "true", "100" } }
  mappings["<C-b>"] = { "scroll", { "-vim.api.nvim_win_get_height(0)", "true", "100" } }
  mappings["<C-f>"] = { "scroll", { "vim.api.nvim_win_get_height(0)", "true", "100" } }
  mappings["<C-y>"] = { "scroll", { "-0.10", "false", "100" } }
  mappings["<C-e>"] = { "scroll", { "0.10", "false", "100" } }
  mappings["zt"] = { "zt", { "100" } }
  mappings["zz"] = { "zz", { "100" } }
  mappings["zb"] = { "zb", { "100" } }

  require("neoscroll.config").set_mappings(mappings)
end

return config
