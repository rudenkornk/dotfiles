return function()
  local cmp = require("cmp")

  -- comparators
  local cmp_compare = require("cmp.config.compare")
  local comparators = {
    require("copilot_cmp.comparators").prioritize,
    require("copilot_cmp.comparators").score,
    cmp_compare.offset,
    cmp_compare.exact,
    -- cmp_compare.scopes,
    cmp_compare.score,
    cmp_compare.recently_used,
    cmp_compare.locality,
    cmp_compare.kind,
    cmp_compare.sort_text,
    cmp_compare.length,
    cmp_compare.order,
  }

  -- setup
  cmp.setup.cmdline("/", {
    mapping = require("cmp").mapping.preset.cmdline(),
    sources = {
      { name = "buffer" },
      { name = "tmux" },
      { name = "rg" },
    },
  })
  cmp.setup.cmdline(":", {
    mapping = require("cmp").mapping.preset.cmdline(),
    sources = {
      { name = "cmdline" },
      { name = "path" },
      { name = "tmux" },
    },
  })
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
      comparators = comparators,
    },
  }
end
