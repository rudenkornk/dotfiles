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
        -- Some candidates:
        --       yc yd          ym yo yp yq    yu yx
        -- ga gb       gj gk gl gm
        --       dc             dm    dp dq dr du dx dy
        --          cd          cm co cp cq cr cu cx cy
        add = "gm",
        delete = "dm",
        find = "gj",
        find_left = "gk",
        highlight = "ga",
        replace = "cm",
      },
    },
  },
  {
    "folke/edgy.nvim",
    enabled = false, -- weird bugs making terminal and other side windows to unexpectedly exit
    opts = require("plugins.configs.edgy").opts,
  },
  {
    "folke/snacks.nvim",
    opts = require("plugins.configs.snacks").opts,
    keys = require("plugins.configs.snacks").keys,
  },
  {
    "folke/trouble.nvim",
    keys = {
      { "<leader>h", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
    },
  },
  {
    "ggandor/flit.nvim",
    -- https://github.com/LazyVim/LazyVim/discussions/6037
    opts = { labeled_modes = "nxo" },
  },
  {
    "gbprod/yanky.nvim",
    opts = { highlight = { on_put = false, on_yank = false, timer = 0 } },
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
    "nvim-treesitter/nvim-treesitter",
    opts = require("plugins.configs.treesitter"),
  },
  {
    "saghen/blink.cmp",
    dependencies = require("plugins.configs.blink").dependencies,
    opts = require("plugins.configs.blink").opts,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format", "ruff_fix" },
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = require("plugins.configs.mason"),
  },

  {
    "aserowy/tmux.nvim",
    event = "VeryLazy",
    config = require("plugins.configs.tmux").config,
    opts = require("plugins.configs.tmux").opts,
    keys = require("plugins.configs.tmux").keys,
  },
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    -- jk combination conflicts with scrolling in lazygit
    -- jj messes up with visual mode
    opts = {
      default_mappings = false,
      mappings = {
        i = { l = { j = "<Esc>" }, ["д"] = { ["о"] = "<Esc>" }, ["_"] = { ["("] = "<Esc>" } },
        c = { l = { j = "<C-c>" } },
        t = { l = { j = "<C-\\><C-n>" }, ["д"] = { ["о"] = "<Esc>" }, ["_"] = { ["("] = "<Esc>" } },
        v = { l = { j = "<Esc>" }, ["д"] = { ["о"] = "<Esc>" }, ["_"] = { ["("] = "<Esc>" } },
        s = { l = { j = "<Esc>" } },
      },
    },
  },
  { "petertriho/nvim-scrollbar", event = "VeryLazy", config = true },
  {
    "tamton-aquib/duck.nvim",
    keys = require("plugins.configs.duck").keys,
  },
}
