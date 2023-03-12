local manifest = require("custom.plugins.manifest")

return {
  ["andersevenrud/cmp-tmux"] = {
    commit = manifest["andersevenrud/cmp-tmux"].commit,
    after = "nvim-cmp",
  },
  ["aserowy/tmux.nvim"] = {
    commit = manifest["aserowy/tmux.nvim"].commit,
    after = "nvim-treesitter",
    keys = { "c", "d", "y" },
    module = "tmux",
    config = function()
      return require("tmux").setup({
        navigation = {
          enable_default_keybindings = false,
        },
        resize = {
          enable_default_keybindings = false,
          resize_step_x = 5,
          resize_step_y = 5,
        },
      })
    end,
  },
  ["ethanholz/nvim-lastplace"] = {
    commit = manifest["ethanholz/nvim-lastplace"].commit,
    event = "VimEnter",
    config = function()
      require("nvim-lastplace").setup()
    end,
  },
  ["folke/noice.nvim"] = {
    commit = manifest["folke/noice.nvim"].commit,
    event = "VimEnter",
    config = function()
      require("noice").setup({
        lsp = {
          -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
        -- you can enable a preset for easier configuration
        presets = {
          bottom_search = true, -- use a classic bottom cmdline for search
          command_palette = true, -- position the cmdline and popupmenu together
          long_message_to_split = true, -- long messages will be sent to a split
          inc_rename = false, -- enables an input dialog for inc-rename.nvim
          lsp_doc_border = false, -- add a border to hover docs and signature help
        },
      })
    end,
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
    disable = true,
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
  ["hrsh7th/nvim-cmp"] = {
    commit = manifest["hrsh7th/nvim-cmp"].commit,
    override_options = require("custom.plugins.cmp"),
  },
  ["jose-elias-alvarez/null-ls.nvim"] = require("custom.plugins.null-ls"),
  ["karb94/neoscroll.nvim"] = {
    commit = manifest["karb94/neoscroll.nvim"].commit,
    disable = true, -- too laggy on my machine
    event = "WinScrolled",
    config = require("custom.plugins.neoscroll"),
  },
  ["kylechui/nvim-surround"] = {
    commit = manifest["kylechui/nvim-surround"].commit,
    keys = { "c", "d", "y" },
    after = "tmux.nvim",
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
  ["mfussenegger/nvim-dap"] = {
    commit = manifest["mfussenegger/nvim-dap"].commit,
    module = "dap",
  },
  ["mfussenegger/nvim-dap-python"] = {
    commit = manifest["mfussenegger/nvim-dap-python"].commit,
    after = "nvim-dap",
    config = function()
      require("dap-python").setup("~/.local/share/nvim/mason/packages/debugpy/venv/bin/python3")
    end,
  },
  ["monaqa/dial.nvim"] = {
    commit = manifest["monaqa/dial.nvim"].commit,
    module = "dial",
    config = require("custom.plugins.dial"),
  },
  ["mrjones2014/nvim-ts-rainbow"] = {
    commit = manifest["mrjones2014/nvim-ts-rainbow"].commit,
    after = "nvim-treesitter",
  },
  ["MunifTanjim/nui.nvim"] = {
    commit = manifest["MunifTanjim/nui.nvim"].commit,
    module = "nui",
  },
  ["neovim/nvim-lspconfig"] = {
    commit = manifest["neovim/nvim-lspconfig"].commit,
    config = require("custom.plugins.lspconfig"),
  },
  ["numToStr/Comment.nvim"] = { commit = manifest["numToStr/Comment.nvim"].commit },
  ["NvChad/base46"] = { commit = manifest["NvChad/base46"].commit },
  ["NvChad/extensions"] = { commit = manifest["NvChad/extensions"].commit },
  ["NvChad/nvim-colorizer.lua"] = { commit = manifest["NvChad/nvim-colorizer.lua"].commit },
  ["NvChad/nvterm"] = { commit = manifest["NvChad/nvterm"].commit },
  ["NvChad/ui"] = {
    commit = manifest["NvChad/ui"].commit,
    override_options = require("custom.plugins.ui"),
  },
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
  ["nvim-tree/nvim-tree.lua"] = {
    commit = manifest["nvim-tree/nvim-tree.lua"].commit,
    override_options = {
      renderer = {
        symlink_destination = false,
      },
    },
  },
  ["nvim-tree/nvim-web-devicons"] = {
    commit = manifest["nvim-tree/nvim-web-devicons"].commit,
  },
  ["nvim-treesitter/nvim-treesitter"] = {
    commit = manifest["nvim-treesitter/nvim-treesitter"].commit,
    override_options = require("custom.plugins.treesitter"),
  },
  ["nvim-treesitter/nvim-treesitter-context"] = {
    commit = manifest["nvim-treesitter/nvim-treesitter-context"].commit,
    after = "nvim-treesitter",
  },
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
  ["petertriho/nvim-scrollbar"] = {
    commit = manifest["petertriho/nvim-scrollbar"].commit,
    after = "nvim-treesitter",
    config = function()
      require("scrollbar").setup()
    end,
  },
  ["phaazon/hop.nvim"] = {
    -- Alternative is ggandor/leap.nvim, which has nice "auto-jump to the first match" feature.
    -- There is some bug, which makes the first "surround" action (with 'ysf<char>') fail.
    -- Consecutive "surround" actions work fine.
    -- As a tradeof, disabling auto-jump allows unidirectional search, which includes the whole screen.
    -- (Auto-jump is limited to anchors, which cannot be used as some meaningful actions like 'y', 'c' or 'd')
    commit = manifest["phaazon/hop.nvim"].commit,
    module = "hop",
    config = function()
      require("hop").setup()
    end,
  },
  ["rafamadriz/friendly-snippets"] = {
    commit = manifest["rafamadriz/friendly-snippets"].commit,
    event = {
      "InsertEnter",
      "CmdlineEnter",
    },
  },
  ["rcarriga/nvim-notify"] = {
    commit = manifest["rcarriga/nvim-notify"].commit,
    module = "notify",
    config = function()
      require("notify").setup({
        stages = "fade",
        timeout = 1000,
        render = "compact",
      })
      vim.notify = require("notify")
    end,
  },
  ["rmagatti/goto-preview"] = {
    commit = manifest["rmagatti/goto-preview"].commit,
    module = "goto-preview",
    config = function()
      require("goto-preview").setup()
    end,
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
  ["theHamsta/nvim-dap-virtual-text"] = {
    commit = manifest["theHamsta/nvim-dap-virtual-text"].commit,
    after = "nvim-dap",
    config = function()
      require("nvim-dap-virtual-text").setup()
    end,
  },
  ["tpope/vim-repeat"] = {
    commit = manifest["tpope/vim-repeat"].commit,
    keys = { "." },
  },
  ["wbthomason/packer.nvim"] = { commit = manifest["wbthomason/packer.nvim"].commit },
  ["weilbith/nvim-code-action-menu"] = {
    commit = manifest["weilbith/nvim-code-action-menu"].commit,
    cmd = "CodeActionMenu",
  },
  ["williamboman/mason.nvim"] = {
    commit = manifest["williamboman/mason.nvim"].commit,
    override_options = require("custom.plugins.mason"),
  },
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
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },
  ["ziontee113/syntax-tree-surfer"] = {
    commit = manifest["ziontee113/syntax-tree-surfer"].commit,
    module = "syntax-tree-surfer",
    cmd = "STS*",
    config = function()
      require("syntax-tree-surfer").setup()
    end,
  },
}
