return function()
  local cmp = require("cmp")
  return {
    sources = {
      { name = "copilot" },
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
        if entry.source.name == "copilot" then
          kind = "Copilot"
          icon = " "
          vim_item.kind_hl_group = "CmpItemKindCopilot"
        end
        vim_item.kind = string.format("%s %s", icon, kind)
        return vim_item
      end,
    },
    sorting = {
      priority_weight = 2,
      comparators = {
        require("copilot_cmp.comparators").prioritize,
        require("copilot_cmp.comparators").score,
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
