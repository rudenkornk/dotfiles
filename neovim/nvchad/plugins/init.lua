local M = {}

M.override = {
  ["NvChad/ui"] = require("custom/plugins/ui"),
  ["lukas-reineke/indent-blankline.nvim"] = require("custom/plugins/indent-blankline"),
  ["nvim-telescope/telescope.nvim"] = require("custom/plugins/telescope"),
  ["nvim-treesitter/nvim-treesitter"] = require("custom/plugins/treesitter"),
}

M.remove = {}
M.user = {
  ["RRethy/vim-illuminate"] = {},
  ["godlygeek/tabular"] = {},
  ["jose-elias-alvarez/null-ls.nvim"] = require("custom/plugins/null-ls"),
  ["kylechui/nvim-surround"] = require("custom/plugins/surround"),
  ["max397574/better-escape.nvim"] = require("custom/plugins/better-escape"),
  ["neovim/nvim-lspconfig"] = require("custom/plugins/lspconfig"),
  ["numToStr/Navigator.nvim"] = require("custom/plugins/Navigator"),
  ["roxma/vim-tmux-clipboard"] = {},
}

return M
