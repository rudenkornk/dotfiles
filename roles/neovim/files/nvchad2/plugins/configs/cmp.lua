local M = {}

M.opts = function(_, opts)
  local cmp = require("cmp")

  local pythonic_dunder_cmp = function(entry1, entry2)
    -- Thanks to https://github.com/lukas-reineke/cmp-under-comparator
    local _, entry1_under = entry1.completion_item.label:find("^_+")
    local _, entry2_under = entry2.completion_item.label:find("^_+")
    entry1_under = entry1_under or 0
    entry2_under = entry2_under or 0
    if entry1_under > entry2_under then
      return false
    elseif entry1_under < entry2_under then
      return true
    end
  end

  -- format
  local nvchad_format = opts.formatting.format
  local sources = {
    ai = { display_name = "AI", icon = "ﱦ", menu_hl = "CmpItemMenuAI" },
    buffer = { display_name = "buffer", icon = "", menu_hl = "CmpItemMenuBuffer" },
    cmdline = { display_name = "cmdline", icon = "", menu_hl = "CmpItemCmdLine" },
    cmp_tabnine = { display_name = "tabnine", icon = "", menu_hl = "CmpItemMenuTabnine" },
    copilot = { display_name = "copilot", icon = "", menu_hl = "CmpItemMenuCopilot" },
    git = { display_name = "git", icon = "", menu_hl = "CmpItemMenuGit" },
    luasnip = { display_name = "luasnip", icon = "", menu_hl = "CmpItemMenuLuasnip" },
    emoji = { display_name = "emoji", icon = "󱗌", menu_hl = "CmpItemMenuEmoji" },
    nvim_lsp = { display_name = "lsp", icon = "", menu_hl = "CmpItemMenuLSP" },
    path = { display_name = "path", icon = "פּ", menu_hl = "CmpItemMenuPath" },
    rg = { display_name = "rg", icon = "", menu_hl = "CmpItemMenuRipGrep" },
    tmux = { display_name = "tmux", icon = "", menu_hl = "CmpItemMenuTmux" },
  }
  local format = function(entry, item)
    item = nvchad_format(_, item)
    local source_name = entry.source.name
    if source_name == "copilot" or source_name == "cmp_tabnine" then
      source_name = "ai"
    end
    local menu = string.format("%s %s", sources[source_name].icon, sources[source_name].display_name)
    item.menu = menu
    item.menu_hl_group = sources[source_name].menu_hl
    item.abbr = string.sub(item.abbr, 1, 50)
    return item
  end

  -- comparators
  local copilot_compare = require("copilot_cmp.comparators")
  local cmp_compare = require("cmp.config.compare")
  local comparators = {
    cmp_compare.offset,
    cmp_compare.exact,
    -- cmp_compare.scopes,
    cmp_compare.score,
    pythonic_dunder_cmp,
    cmp_compare.recently_used,
    cmp_compare.locality,
    cmp_compare.kind,
    cmp_compare.sort_text,
    cmp_compare.length,
    cmp_compare.order,
  }
  table.insert(comparators, 1, copilot_compare.score)
  table.insert(comparators, 1, copilot_compare.prioritize)

  -- mapping
  local map_funcs = cmp.mapping
  local mapping = {
    ["<C-f>"] = map_funcs.scroll_docs(8),
    ["<C-b>"] = map_funcs.scroll_docs(-8),
    ["<C-d>"] = map_funcs.scroll_docs(4),
    ["<C-u>"] = map_funcs.scroll_docs(-4),
  }

  opts.formatting = { format=format }
  opts.mapping = vim.tbl_deep_extend("force", opts.mapping, mapping)
  table.insert(opts.sources, { name = "buffer" })
  table.insert(opts.sources, { name = "copilot" })
  table.insert(opts.sources, { name = "emoji" })
  table.insert(opts.sources, { name = "git" })
  table.insert(opts.sources, { name = "luasnip" })
  table.insert(opts.sources, { name = "nvim_lsp" })
  table.insert(opts.sources, { name = "nvim_lua" })
  table.insert(opts.sources, { name = "path" })
  table.insert(opts.sources, { name = "tmux" })
  -- table.insert(opts.sources, { name = "rg" }) -- takes too much resources
  opts.sorting = {
    priority_weight = 2,
    comparators = comparators,
  }
  return opts
end

M.config = function(_, opts)
  local cmp = require("cmp")
  cmp.setup(opts)
  cmp.setup.cmdline("/", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = "buffer" },
      { name = "tmux" },
      -- { name = "rg" }, -- takes too much resources
    },
  })
  cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = "cmdline" },
      { name = "path" },
      { name = "tmux" },
    },
  })
end

return M
