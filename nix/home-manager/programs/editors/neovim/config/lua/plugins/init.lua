-- Comments near plugin specifications refer to the LazyVim extras.
-- This allows easier tracking whenever LazyVim decides to deprecate some extras
-- or we change extras set here.

return {
  -- Tweaks for core plugins of LazyVim.
  -- These plugins usually are not tied to some specific feature set,
  -- but rather a generic functionality used by different languages and UI.
  -- As a result, these plugins are tweaked or used by multiple other extras.
  {
    "folke/snacks.nvim", -- Core UI plugin.
    opts = require("plugins.configs.snacks").opts,
    keys = require("plugins.configs.snacks").keys,
  },
  {
    "folke/edgy.nvim", -- Core UI plugin for side windows management.
    enabled = false, -- weird bugs making terminal and other side windows to unexpectedly exit
    opts = require("plugins.configs.edgy").opts,
  },
  {
    "folke/trouble.nvim", -- Core UI plugin for diagnostics.
    keys = {
      { "<leader>h", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
    },
  },
  {
    "nvim-lualine/lualine.nvim", -- Core UI plugin for statusline.
    opts = require("plugins.configs.lualine").opts,
  },
  {
    "nvim-treesitter/nvim-treesitter", -- Core lang plugin.
    opts = require("plugins.configs.treesitter"),
  },
  {
    "mfussenegger/nvim-dap", -- Core DAP plugin.
    keys = require("plugins.configs.dap").keys,
  },
  {
    "stevearc/conform.nvim", -- Core lang plugin for formatting.
    opts = {
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format", "ruff_fix" },
      },
    },
  },
  {
    "saghen/blink.cmp", -- Core lang plugin for completion.
    dependencies = require("plugins.configs.blink").dependencies,
    opts = require("plugins.configs.blink").opts,
  },
  -- Mason plugins for fetching binaries like LSPs, formatters, linters, debuggers.
  -- Completely disable them since we use nix to manage these tools.
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "mason-org/mason-null-ls.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },

  -- LazyVim support for specific features and plugins.
  {
    "nvim-mini/mini.indentscope", -- ui.mini-indentscope
    opts = { draw = { delay = 0, animation = require("mini.indentscope").gen_animation.none() } },
  },
  {
    "nvim-mini/mini.move", -- editor.mini-move
    event = "VeryLazy",
    opts = {
      -- disable '<M-j>' and '<M-k>' mappings conflicting with dap
      mappings = { line_down = "", line_up = "" },
    },
  },
  {
    "nvim-mini/mini.surround", -- coding.mini-surround, editor.leap
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
    "folke/sidekick.nvim", -- ai.sidekick
    keys = require("plugins.configs.sidekick").keys,
  },
  {
    "ggandor/flit.nvim", -- editor.leap
    -- https://github.com/LazyVim/LazyVim/discussions/6037
    opts = { labeled_modes = "nxo" },
  },
  {
    "gbprod/yanky.nvim", -- coding.yanky
    opts = { highlight = { on_put = false, on_yank = false, timer = 0 } },
  },
  {
    "iamcco/markdown-preview.nvim", -- lang.markdown
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
    "chomosuke/typst-preview.nvim", -- lang.typst
    opts = {
      -- By default typst-preview.nvim uses dynamically-downloaded `websocat` binary.
      -- Use nix instead.
      dependencies_bin = { websocat = "websocat" },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim", -- lang.markdown
    opts = require("plugins.configs.render_markdown").opts,
    ft = require("plugins.configs.render_markdown").ft,
  },
  {
    "monaqa/dial.nvim", -- editor.dial
    config = require("plugins.configs.dial").config,
  },
  {
    "zbirenbaum/copilot.lua", -- ai.copilot
    enabled = os.getenv("USERKIND") == "default",
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
      timeout = 200,
      mappings = {
        i = { l = { j = "<Esc>" }, ["д"] = { ["о"] = "<Esc>" } },
        c = { l = { j = "<C-c>" } },
        t = { l = { j = "<C-\\><C-n>" }, ["д"] = { ["о"] = "<Esc>" } },
        v = { l = { j = "<Esc>" }, ["д"] = { ["о"] = "<Esc>" } },
        s = { l = { j = "<Esc>" } },
      },
    },
  },
  { "petertriho/nvim-scrollbar", event = "VeryLazy", config = true },
  {
    "milanglacier/minuet-ai.nvim",
    -- `opts` must be defined (at least to `{}`), otherwise minuet will throw an error.
    opts = require("plugins.configs.minuet").opts,
  },
  {
    "tamton-aquib/duck.nvim",
    keys = require("plugins.configs.duck").keys,
  },
}
