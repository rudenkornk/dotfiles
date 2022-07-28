local M = {}

M.override = {
  ["NvChad/ui"] = require("custom/plugins/ui"),
  ["hrsh7th/nvim-cmp"] = require("custom/plugins/cmp"),
  ["lukas-reineke/indent-blankline.nvim"] = require("custom/plugins/indent-blankline"),
  ["nvim-telescope/telescope.nvim"] = require("custom/plugins/telescope"),
  ["nvim-treesitter/nvim-treesitter"] = require("custom/plugins/treesitter"),
  ["williamboman/mason"] = require("custom/plugins/mason"),
}

M.remove = {}
M.user = {
  ["RRethy/vim-illuminate"] = require("custom/plugins/illuminate"),
  ["andersevenrud/cmp-tmux"] = require("custom/plugins/cmp-tmux"),
  ["folke/trouble.nvim"] = require("custom/plugins/trouble"),
  ["godlygeek/tabular"] = require("custom/plugins/tabular"),
  ["hrsh7th/cmp-cmdline"] = require("custom/plugins/cmp-cmdline"),
  ["jose-elias-alvarez/null-ls.nvim"] = require("custom/plugins/null-ls"),
  ["kylechui/nvim-surround"] = require("custom/plugins/surround"),
  ["lewis6991/gitsigns.nvim"] = require("custom/plugins/gitsigns"),
  ["lukas-reineke/cmp-rg"] = require("custom/plugins/cmp-rg"),
  ["max397574/better-escape.nvim"] = require("custom/plugins/better-escape"),
  ["neovim/nvim-lspconfig"] = require("custom/plugins/lspconfig"),
  ["numToStr/Navigator.nvim"] = require("custom/plugins/Navigator"),
  ["petertriho/cmp-git"] = require("custom/plugins/cmp-git"),
  ["rafamadriz/friendly-snippets"] = require("custom/plugins/friendly-snippets"),
  ["rmagatti/goto-preview"] = require("custom/plugins/goto-preview"),
  ["roxma/vim-tmux-clipboard"] = {},
  ["simrat39/symbols-outline.nvim"] = require("custom/plugins/symbols-outline"),
  ["stevearc/aerial.nvim"] = require("custom/plugins/aerial"),
  ["weilbith/nvim-code-action-menu"] = require("custom/plugins/code-action-menu"),
  ["zbirenbaum/copilot-cmp"] = require("custom/plugins/copilot-cmp"),
  ["zbirenbaum/copilot.lua"] = require("custom/plugins/copilot"),
}

return M
