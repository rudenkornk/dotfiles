return function()
  local cmp = require("cmp")
  return {
    sources = {
      { name = "buffer" },
      { name = "git" },
      { name = "luasnip" },
      { name = "nvim_lsp" },
      { name = "nvim_lua" },
      { name = "path" },
      { name = "rg" },
      { name = "tmux" },
    },
    formatting = {
      format = function(entry, vim_item)
        local icons = require("nvchad_ui.icons").lspkind
        local kind = vim_item.kind
        local icon = icons[kind]
        vim_item.kind = string.format("%s %s", icon, kind)
        return vim_item
      end,
    },
    sorting = {
      priority_weight = 2,
      comparators = {
        cmp.config.compare.offset,
        cmp.config.compare.exact,
        -- cmp.config.compare.scopes,
        cmp.config.compare.score,
        cmp.config.compare.recently_used,
        cmp.config.compare.locality,
        cmp.config.compare.kind,
        cmp.config.compare.sort_text,
        cmp.config.compare.length,
        cmp.config.compare.order,
      },
    },
  }
end
