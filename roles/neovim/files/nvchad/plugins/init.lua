local manifest = require("custom.plugins.manifest")

return {
  ["andersevenrud/cmp-tmux"] = {
    commit = manifest["andersevenrud/cmp-tmux"].commit,
    after = "nvim-cmp",
  },
  ["folke/trouble.nvim"] = {
    commit = manifest["folke/trouble.nvim"].commit,
    cmd = {
      "Trouble",
      "TroubleClose",
      "TroubleToggle",
      "TroubleRefresh",
    },
    config = function()
      require("trouble").setup()
    end,
  },
  ["folke/which-key.nvim"] = {
    commit = manifest["folke/which-key.nvim"].commit,
    disabled = true,
  },
  ["godlygeek/tabular"] = {
    commit = manifest["godlygeek/tabular"].commit,
    cmd = "Tabularize",
  },
  ["goolord/alpha-nvim"] = { commit = manifest["goolord/alpha-nvim"].commit },
  ["hrsh7th/cmp-buffer"] = { commit = manifest["hrsh7th/cmp-buffer"].commit },
  ["hrsh7th/cmp-cmdline"] = {
    commit = manifest["hrsh7th/cmp-cmdline"].commit,
    after = "nvim-cmp",
  },
  ["hrsh7th/cmp-nvim-lsp"] = { commit = manifest["hrsh7th/cmp-nvim-lsp"].commit },
  ["hrsh7th/cmp-nvim-lua"] = { commit = manifest["hrsh7th/cmp-nvim-lua"].commit },
  ["hrsh7th/cmp-path"] = { commit = manifest["hrsh7th/cmp-path"].commit },
  ["hrsh7th/nvim-cmp"] = require("custom.plugins.cmp"),
  ["jose-elias-alvarez/null-ls.nvim"] = require("custom.plugins.null-ls"),
  ["kyazdani42/nvim-tree.lua"] = {
    commit = manifest["kyazdani42/nvim-tree.lua"].commit,
    override_options = {
      renderer = {
        symlink_destination = false,
      },
    },
  },
  ["kyazdani42/nvim-web-devicons"] = {
    commit = manifest["kyazdani42/nvim-web-devicons"].commit,
  },
  ["kylechui/nvim-surround"] = {
    commit = manifest["kylechui/nvim-surround"].commit,
    keys = { "c", "d", "y" },
    after = "vim-tmux-clipboard",
    config = function()
      require("nvim-surround").setup()
    end,
  },
  ["L3MON4D3/LuaSnip"] = { commit = manifest["L3MON4D3/LuaSnip"].commit },
  ["lewis6991/gitsigns.nvim"] = { commit = manifest["lewis6991/gitsigns.nvim"].commit },
  ["lewis6991/impatient.nvim"] = { commit = manifest["lewis6991/impatient.nvim"].commit },
  ["lukas-reineke/cmp-rg"] = {
    commit = manifest["lukas-reineke/cmp-rg"].commit,
    after = "nvim-cmp",
  },
  ["lukas-reineke/indent-blankline.nvim"] = {
    commit = manifest["lukas-reineke/indent-blankline.nvim"].commit,
    after = "nvim-treesitter",
    override_options = {
      show_current_context_start = false,
    },
  },
  ["max397574/better-escape.nvim"] = {
    commit = manifest["max397574/better-escape.nvim"].commit,
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },
  ["neovim/nvim-lspconfig"] = require("custom.plugins.lspconfig"),
  ["numToStr/Comment.nvim"] = { commit = manifest["numToStr/Comment.nvim"].commit },
  ["numToStr/Navigator.nvim"] = {
    commit = manifest["numToStr/Navigator.nvim"].commit,
    -- Alternative to Navigator.nvim + vim-tmux-clipboard is aserowy/tmux.nvim, but
    -- copy sync does not work in it
    cmd = {
      "NavigatorLeft",
      "NavigatorDown",
      "NavigatorUp",
      "NavigatorRight",
      "NavigatorPrevious",
    },
    config = function()
      require("Navigator").setup()
    end,
  },
  ["NvChad/base46"] = { commit = manifest["NvChad/base46"].commit },
  ["NvChad/extensions"] = { commit = manifest["NvChad/extensions"].commit },
  ["NvChad/nvim-colorizer.lua"] = { commit = manifest["NvChad/nvim-colorizer.lua"].commit },
  ["NvChad/nvterm"] = { commit = manifest["NvChad/nvterm"].commit },
  ["NvChad/ui"] = require("custom.plugins.ui"),
  ["nvim-lua/plenary.nvim"] = { commit = manifest["nvim-lua/plenary.nvim"].commit },
  ["nvim-telescope/telescope.nvim"] = {
    commit = manifest["nvim-telescope/telescope.nvim"].commit,
    override_options = {
      defaults = {
        mappings = {
          i = {
            ["<C-f>"] = "results_scrolling_down",
            ["<C-b>"] = "results_scrolling_up",
            ["<C-a>"] = { "<ESC>^Wi", type = "command" },
          },
        },
        scroll_strategy = "limit",
      },
    },
  },
  ["nvim-treesitter/nvim-treesitter"] = require("custom.plugins.treesitter"),
  ["pearofducks/ansible-vim"] = {
    commit = manifest["pearofducks/ansible-vim"].commit,
    after = "nvim-cmp",
  },
  ["petertriho/cmp-git"] = {
    commit = manifest["petertriho/cmp-git"].commit,
    after = "nvim-cmp",
    requires = "nvim-lua/plenary.nvim",
    config = function()
      require("cmp_git").setup()
    end,
  },
  ["rafamadriz/friendly-snippets"] = {
    commit = manifest["rafamadriz/friendly-snippets"].commit,
    -- The only purpose of this config is to trigger nvim-cmp on CmdlineEnter event
    event = {
      "InsertEnter",
      "CmdlineEnter",
    },
  },
  ["rmagatti/goto-preview"] = {
    commit = manifest["rmagatti/goto-preview"].commit,
    module = "goto-preview",
    config = function()
      require("goto-preview").setup()
    end,
  },
  ["roxma/vim-tmux-clipboard"] = {
    commit = manifest["roxma/vim-tmux-clipboard"].commit,
    keys = { "c", "d", "y" },
  },
  ["RRethy/vim-illuminate"] = {
    commit = manifest["RRethy/vim-illuminate"].commit,
    module = "illuminate",
  },
  ["saadparwaiz1/cmp_luasnip"] = { commit = manifest["saadparwaiz1/cmp_luasnip"].commit },
  ["simrat39/symbols-outline.nvim"] = {
    commit = manifest["simrat39/symbols-outline.nvim"].commit,
    cmd = {
      "SymbolsOutline",
      "SymbolsOutlineOpen",
      "SymbolsOutlineClose",
    },
    setup = function()
      vim.g.symbols_outline = {
        highlight_hovered_item = false,
      }
    end,
  },
  ["stevearc/aerial.nvim"] = {
    commit = manifest["stevearc/aerial.nvim"].commit,
    cmd = {
      "Aerial*",
    },
    config = function()
      require("aerial").setup()
    end,
  },
  ["wbthomason/packer.nvim"] = { commit = manifest["wbthomason/packer.nvim"].commit },
  ["weilbith/nvim-code-action-menu"] = {
    commit = manifest["weilbith/nvim-code-action-menu"].commit,
    cmd = "CodeActionMenu",
  },
  ["williamboman/mason.nvim"] = require("custom.plugins.mason"),
  ["windwp/nvim-autopairs"] = { commit = manifest["windwp/nvim-autopairs"].commit },
  ["zbirenbaum/copilot-cmp"] = {
    commit = manifest["zbirenbaum/copilot-cmp"].commit,
    after = { "copilot.lua" },
    config = function()
      require("copilot_cmp").setup()
    end,
  },
  ["zbirenbaum/copilot.lua"] = {
    commit = manifest["zbirenbaum/copilot.lua"].commit,
    after = "nvim-cmp",
    config = function()
      require("copilot").setup()
    end,
  },
}
