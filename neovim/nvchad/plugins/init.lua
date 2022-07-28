local M = {}
local small_configs = require("custom/plugins/small_configs")

M.override = {
  ["NvChad/ui"] = require("custom/plugins/ui"),
  ["hrsh7th/nvim-cmp"] = require("custom/plugins/cmp"),
  ["lukas-reineke/indent-blankline.nvim"] = small_configs.indent_blankline,
  ["nvim-telescope/telescope.nvim"] = small_configs.telescope,
  ["nvim-treesitter/nvim-treesitter"] = require("custom/plugins/treesitter"),
  ["williamboman/mason"] = require("custom/plugins/mason"),
}

M.remove = {}
M.user = {
  ["RRethy/vim-illuminate"] = small_configs.illuminate,
  ["andersevenrud/cmp-tmux"] = small_configs.cmp_tmux,
  ["folke/trouble.nvim"] = small_configs.trouble,
  ["godlygeek/tabular"] = small_configs.tabular,
  ["hrsh7th/cmp-cmdline"] = small_configs.cmp_cmdline,
  ["jose-elias-alvarez/null-ls.nvim"] = require("custom/plugins/null-ls"),
  ["kylechui/nvim-surround"] = small_configs.surround,
  ["lewis6991/gitsigns.nvim"] = small_configs.gitsigns,
  ["lukas-reineke/cmp-rg"] = small_configs.cmp_rg,
  ["max397574/better-escape.nvim"] = small_configs.better_escape,
  ["neovim/nvim-lspconfig"] = require("custom/plugins/lspconfig"),
  ["numToStr/Navigator.nvim"] = small_configs.navigator,
  ["petertriho/cmp-git"] = small_configs.cmp_git,
  ["rafamadriz/friendly-snippets"] = small_configs.friendly_snippets,
  ["rmagatti/goto-preview"] = small_configs.goto_preview,
  ["roxma/vim-tmux-clipboard"] = small_configs.vim_tmux_clipboard,
  ["simrat39/symbols-outline.nvim"] = small_configs.symbols_outline,
  ["stevearc/aerial.nvim"] = small_configs.aerial,
  ["tzachar/cmp-tabnine"] = small_configs.cmp_tabnine,
  ["weilbith/nvim-code-action-menu"] = small_configs.code_action_menu,
  ["zbirenbaum/copilot-cmp"] = small_configs.copilot_cmp,
  ["zbirenbaum/copilot.lua"] = small_configs.copilot,
}

return M
