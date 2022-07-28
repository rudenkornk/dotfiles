return function()
  local cmp = require("cmp")

  -- comparators
  local copilot_loaded, copilot_compare = pcall(require, "copilot_cmp.comparators")
  local cmp_compare = require("cmp.config.compare")
  local comparators = {
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
  if copilot_loaded then
    table.insert(comparators, 1, copilot_compare.score)
    table.insert(comparators, 1, copilot_compare.prioritize)
  end

  -- mapping
  local map_funcs = cmp.mapping
  local mapping = {
    ["<C-f>"] = map_funcs.scroll_docs(8),
    ["<C-b>"] = map_funcs.scroll_docs(-8),
    ["<C-d>"] = map_funcs.scroll_docs(4),
    ["<C-u>"] = map_funcs.scroll_docs(-4),
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
    mapping = mapping,
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
