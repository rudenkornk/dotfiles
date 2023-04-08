return {
  { "stevearc/aerial.nvim", cmd = "AerialToggle", config = true },
  { "max397574/better-escape.nvim", event = "InsertEnter", config = true },
  { "hrsh7th/cmp-cmdline" },
  { "hrsh7th/cmp-emoji" },
  { "petertriho/cmp-git", config = true },
  { "lukas-reineke/cmp-rg" },
  { "andersevenrud/cmp-tmux" },
  {
    "zbirenbaum/copilot-cmp",
    config = true,
    dependencies = {
      "zbirenbaum/copilot.lua",
    },
  },
  {
    "zbirenbaum/copilot.lua",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
    },
  },
  { "monaqa/dial.nvim", config = require("custom.plugins.configs.dial") },
  { "rmagatti/goto-preview", config = true },
  {
    "phaazon/hop.nvim",
    -- Alternative is ggandor/leap.nvim, which has nice "auto-jump to the first match" feature.
    -- There is some bug, which makes the first "surround" action (with 'ysf<char>') fail.
    -- Consecutive "surround" actions work fine.
    -- As a tradeof, disabling auto-jump allows unidirectional search, which includes the whole screen.
    -- (Auto-jump is limited to anchors, which cannot be used as some meaningful actions like 'y', 'c' or 'd')
    config = true,
  },
  { "lukas-reineke/indent-blankline.nvim", opts = { show_current_context_start = false } },
  { "williamboman/mason.nvim", opts = require("custom.plugins.configs.mason") },
  {
    "karb94/neoscroll.nvim",
    enabled = true,
    event = "WinScrolled",
    config = require("custom.plugins.configs.neoscroll"),
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = function()
      return {
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
      }
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
  },
  { "MunifTanjim/nui.nvim" },
  { "jose-elias-alvarez/null-ls.nvim", opts = require("custom.plugins.configs.null-ls") },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-emoji",
      "petertriho/cmp-git",
      "lukas-reineke/cmp-rg",
      "andersevenrud/cmp-tmux",
      "zbirenbaum/copilot-cmp",
    },
    opts = require("custom.plugins.configs.cmp").opts,
    config = require("custom.plugins.configs.cmp").config,
  },
  { "weilbith/nvim-code-action-menu", cmd = "CodeActionMenu" },
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "mfussenegger/nvim-dap-python",
      "mfussenegger/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
    },
  },
  { "mfussenegger/nvim-dap-python" },
  { "mfussenegger/nvim-dap-ui" },
  { "theHamsta/nvim-dap-virtual-text", config = true },
  { "ethanholz/nvim-lastplace", event = "VimEnter", config = true },
  {
    "neovim/nvim-lspconfig",
    config = require("custom.plugins.configs.lspconfig"),
    dependencies = {
      "jose-elias-alvarez/null-ls.nvim",
    },
  },
  {
    "rcarriga/nvim-notify",
    opts = {
      stages = "fade",
      timeout = 1000,
      render = "compact",
    },
    config = function(_, opts)
      require("notify").setup(opts)
      vim.notify = require("notify")
    end,
  },
  { "petertriho/nvim-scrollbar", event = "VeryLazy", config = true },
  { "chrisgrieser/nvim-spider", opts = { skipInsignificantPunctuation = false } },
  { "kylechui/nvim-surround", keys = { "c", "d", "y" }, config = true },
  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      renderer = {
        symlink_destination = false,
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = require("custom.plugins.configs.treesitter"),
    dependencies = {
      "mrjones2014/nvim-ts-rainbow",
      "nvim-treesitter/nvim-treesitter-context",
    },
  },
  { "nvim-treesitter/nvim-treesitter-context" },
  { "mrjones2014/nvim-ts-rainbow" },
  {
    "simrat39/symbols-outline.nvim",
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
  {
    "ziontee113/syntax-tree-surfer",
    config = true,
  },
  { "godlygeek/tabular", cmd = "Tabularize" },
  {
    "nvim-telescope/telescope.nvim",
    opts = {
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
  {
    "aserowy/tmux.nvim",
    event = "VeryLazy",
    opts = {
      navigation = {
        enable_default_keybindings = false,
      },
      resize = {
        enable_default_keybindings = false,
        resize_step_x = 5,
        resize_step_y = 5,
      },
    },
  },
  {
    "folke/trouble.nvim",
    cmd = {
      "Trouble",
      "TroubleClose",
      "TroubleToggle",
      "TroubleRefresh",
    },
    config = true,
  },
  { "RRethy/vim-illuminate" },
  { "tpope/vim-repeat", keys = { "." } },
  { "folke/which-key.nvim", enabled = false },
}
