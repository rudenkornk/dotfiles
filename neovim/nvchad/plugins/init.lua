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
  ["jose-elias-alvarez/null-ls.nvim"] = require("custom/plugins/null-ls"),
  ["kylechui/nvim-surround"] = require("custom/plugins/surround"),
  ["lukas-reineke/cmp-rg"] = require("custom/plugins/cmp-rg"),
  ["max397574/better-escape.nvim"] = require("custom/plugins/better-escape"),
  ["neovim/nvim-lspconfig"] = require("custom/plugins/lspconfig"),
  ["numToStr/Navigator.nvim"] = require("custom/plugins/Navigator"),
  ["roxma/vim-tmux-clipboard"] = {},
  ["stevearc/aerial.nvim"] = require("custom/plugins/aerial"),
}

return M
