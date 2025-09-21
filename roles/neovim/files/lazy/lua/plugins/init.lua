return {
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
    "iamcco/markdown-preview.nvim",
    config = function()
      -- For this `vim.cmd(...)` see original in LazyVim:
      -- https://github.com/LazyVim/lazyvim.github.io/blob/5cc96146d96bb61ad915088bc3eec4151643cd6f/docs/extras/lang/markdown.md#markdown-previewnvim
      vim.cmd([[do FileType]])
      -- Do not close preview on buffer switch.
      -- See https://github.com/iamcco/markdown-preview.nvim/tree/a923f5fc5ba36a3b17e289dc35dc17f66d0548ee?tab=readme-ov-file#markdownpreview-config
      vim.g.mkdp_auto_close = 0
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      -- Prevent rendered and normal versions to be different in lines,
      -- which makes document "flicker" when switching between them.
      code = { border = "thick" },
      pipe_table = { style = "normal" },
      file_types = { "markdown", "Avante" },
    },
    ft = { "markdown", "Avante" },
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
    "yetone/avante.nvim",
    event = "VeryLazy",
    build = require("plugins.configs.avante").build,
    opts = require("plugins.configs.avante").opts,
  },
  {
    "HakonHarnes/img-clip.nvim",
    keys = {
      { "<leader>P", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
    },
  },
  {
    "tamton-aquib/duck.nvim",
    keys = require("plugins.configs.duck").keys,
  },
}
