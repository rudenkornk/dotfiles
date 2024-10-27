return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    opts = require("plugins.configs.copilot_chat").opts,
  },
  {
    "echasnovski/mini.indentscope",
    opts = { draw = { delay = 0, animation = require("mini.indentscope").gen_animation.none() } },
  },
  {
    "echasnovski/mini.move",
    event = "VeryLazy",
    opts = {
      -- disable '<M-j>' and '<M-k>' mappings conflicting with dap
      mappings = { line_down = "", line_up = "" },
    },
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
    "folke/trouble.nvim",
    keys = {
      { "<leader>h", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
    },
  },
  {
    "gbprod/yanky.nvim",
    opts = { highlight = { on_put = false, on_yank = false, timer = 0 } },
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
    "mfussenegger/nvim-dap",
    keys = require("plugins.configs.dap").keys,
  },
  {
    "monaqa/dial.nvim",
    config = require("plugins.configs.dial").config,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = require("plugins.configs.lualine").opts,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = { filesystem = { filtered_items = { hide_dotfiles = false, hide_gitignored = false } } },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = require("plugins.configs.treesitter"),
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
    "williamboman/mason.nvim",
    opts = require("plugins.configs.mason"),
  },
  {
    "linux-cultist/venv-selector.nvim",
    opts = { settings = { options = { notify_user_on_venv_activation = false } } },
  },

  {
    "aserowy/tmux.nvim",
    event = "VeryLazy",
    opts = require("plugins.configs.tmux").opts,
    keys = require("plugins.configs.tmux").keys,
  },
  { "max397574/better-escape.nvim", event = "InsertEnter", config = true },
  { "petertriho/nvim-scrollbar", event = "VeryLazy", config = true },
  {
    "tamton-aquib/duck.nvim",
    keys = require("plugins.configs.duck").keys,
  },
}
