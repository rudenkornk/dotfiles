return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = require("plugins.configs.treesitter"),
  },
  {
    "williamboman/mason.nvim",
    opts = require("plugins.configs.mason"),
  },
  {
    "L3MON4D3/LuaSnip",
    keys = function()
      -- Disable default <tab> and <s-tab> behavior in LuaSnip for Supertab
      return {}
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "andersevenrud/cmp-tmux",
      "hrsh7th/cmp-emoji",
    },
    opts = require("plugins.configs.cmp").opts,
  },
  {
    "ggandor/leap.nvim",
    enabled = true,
    keys = {
      { "s", mode = { "n", "x", "o" }, false },
      { "S", mode = { "n", "x", "o" }, false },
    },
  },
  {
    "echasnovski/mini.indentscope",
    opts = {
      draw = {
        delay = 0,
        animation = require("mini.indentscope").gen_animation.none(),
      },
    },
  },
  {
    "gbprod/yanky.nvim",
    opts = { highlight = { on_put = false, on_yank = false, timer = 0 } },
  },
  {
    "echasnovski/mini.surround",
    opts = {
      mappings = {
        add = "ys",
        delete = "ds",
        replace = "cs",
      },
    },
  },
  {
    "echasnovski/mini.pairs",
    enabled = false,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = require("plugins.configs.lualine").opts,
  },
  {
    "nvim-telescope/telescope.nvim",
    opts = require("plugins.configs.telescope").opts,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "isort", "black" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = require("plugins.configs.lint").opts,
  },
  {
    "folke/trouble.nvim",
    keys = {
      { "<leader>r", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "Document Diagnostics (Trouble)" },
    },
  },
  {
    "mfussenegger/nvim-dap",
    keys = require("plugins.configs.dap").keys,
  },

  {
    "debugloop/telescope-undo.nvim",
    keys = {
      { "<leader>fu", "<cmd> Telescope undo <CR>", desc = "Telescope undo" },
    },
  },
  {
    "aserowy/tmux.nvim",
    event = "VeryLazy",
    opts = require("plugins.configs.tmux").opts,
    keys = require("plugins.configs.tmux").keys,
  },
  {
    "monaqa/dial.nvim",
    config = require("plugins.configs.dial").config,
    keys = require("plugins.configs.dial").keys,
  },
  {
    -- Alternative: https://github.com/nvim-treesitter/nvim-treesitter-textobjects#text-objects-swap
    -- But it works only for moving nodes up/down, not for left/right.
    "ziontee113/syntax-tree-surfer",
    config = true,
    keys = require("plugins.configs.sts").keys,
  },
  { "petertriho/nvim-scrollbar", event = "VeryLazy", config = true },
  { "max397574/better-escape.nvim", event = "InsertEnter", config = true },
  {
    "tamton-aquib/duck.nvim",
    keys = require("plugins.configs.duck").keys,
  },
}
