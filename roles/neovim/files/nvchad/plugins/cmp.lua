local M = {}

local manifest = require("custom.plugins.manifest")

M.commit = manifest["hrsh7th/nvim-cmp"].commit
M.override_options = function()
  local cmp = require("cmp")

  -- format
  local token_icons = require("nvchad_ui.icons").lspkind
  token_icons["AI"] = "ﱦ "
  local sources = {
    buffer = { display_name = "buffer", icon = "", menu_hl = "CmpItemMenuBuffer" },
    cmdline = { display_name = "cmdline", icon = "", menu_hl = "CmpItemCmdLine" },
    cmp_tabnine = { display_name = "tabnine", icon = "", menu_hl = "CmpItemMenuTabnine" },
    copilot = { display_name = "copilot", icon = "", menu_hl = "CmpItemMenuCopilot" },
    git = { display_name = "git", icon = "", menu_hl = "CmpItemMenuGit" },
    luasnip = { display_name = "luasnip", icon = "", menu_hl = "CmpItemMenuLuasnip" },
    nvim_lsp = { display_name = "lsp", icon = "", menu_hl = "CmpItemMenuLSP" },
    nvim_lua = { display_name = "neovim lua", icon = "", menu_hl = "CmpItemMenuNeovimLua" },
    path = { display_name = "path", icon = "פּ", menu_hl = "CmpItemMenuPath" },
    rg = { display_name = "rg", icon = "", menu_hl = "CmpItemMenuRipGrep" },
    tmux = { display_name = "tmux", icon = "", menu_hl = "CmpItemMenuTmux" },
  }
  local format = function(entry, vim_item)
    local source_name = entry.source.name
    local kind = vim_item.kind
    local menu = string.format("%s %s", sources[source_name].icon, sources[source_name].display_name)
    if source_name == "copilot" or source_name == "cmp_tabnine" then
      kind = "AI"
      vim_item.kind_hl_group = sources[source_name].menu_hl
      if vim_item.menu then
        menu = menu .. " " .. vim_item.menu
      end
    end
    local icon = token_icons[kind]
    vim_item.kind = string.format("%s %s", icon, kind)
    vim_item.menu = menu
    vim_item.menu_hl_group = sources[source_name].menu_hl
    vim_item.abbr = string.sub(vim_item.abbr, 1, 50)
    return vim_item
  end

  -- comparators
  local tabnine_loaded, tabnine = pcall(require, "cmp_tabnine")
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
  if tabnine_loaded then
    table.insert(comparators, 1, tabnine.compare)
  end
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
      -- { name = "rg" }, -- takes too much resources
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
      { name = "cmp_tabnine" },
      { name = "nvim_lsp" },
      { name = "nvim_lua" },
      { name = "luasnip" },
      { name = "buffer" },
      { name = "git" },
      { name = "path" },
      { name = "tmux" },
      -- { name = "rg" }, -- takes too much resources
    },
    formatting = {
      format = format,
    },
    sorting = {
      priority_weight = 2,
      comparators = comparators,
    },
  }
end

return M
