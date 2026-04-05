return {
  -- Alternatives:

  -- https://github.com/michaelb/sniprun (> 1700 stars)
  --   Generic interactive REPL.

  -- https://github.com/Vigemus/iron.nvim (> 1300 stars)
  --   Generic interactive REPL.
  {
    "Vigemus/iron.nvim",
    cmd = { "IronRepl", "IronFocus", "IronHide", "IronRestart", "IronAttach", "IronSend", "IronWatch" },
    keys = {

      -- <leader>r* : REPL / kernel session management
      { "<leader>rr", "<cmd>IronRepl<cr>", desc = "Toggle REPL" },
      { "<leader>rn", "<cmd>IronFocus<cr>", desc = "Focus REPL" },
      { "<leader>rh", "<cmd>IronHide<cr>", desc = "Hide REPL" },
      { "<leader>rt", "<cmd>IronRestart<cr>", desc = "Restart REPL" },
      {
        "<leader>ru",
        function()
          require("iron.core").send(nil, "\3")
        end,
        desc = "Interrupt REPL",
      },
      {
        "<leader>re",
        function()
          require("iron.core").close_repl()
        end,
        desc = "Exit REPL",
      },
      {
        "<leader>rw",
        function()
          require("iron.core").send(nil, "\12")
        end,
        desc = "Clear REPL",
      },

      -- <leader>k* : send code / execute (k = kernel execution)
      {
        "<leader>kj",
        function()
          require("iron.core").send_code_block(false)
        end,
        desc = "Send cell",
      },
      {
        "<leader>kk",
        function()
          require("iron.core").send_code_block(true)
        end,
        desc = "Send cell and move",
      },
      {
        "<leader>kk",
        function()
          require("iron.core").visual_send()
        end,
        desc = "Send selection",
        mode = "x",
      },
      {
        "<leader>kl",
        function()
          require("iron.core").send_line()
        end,
        desc = "Send line",
      },
      {
        "<leader>km",
        function()
          require("iron.core").send_paragraph()
        end,
        desc = "Send paragraph",
      },
      {
        "<leader>kf",
        function()
          require("iron.core").send_file()
        end,
        desc = "Send file",
      },
      {
        "<leader>kz",
        function()
          require("iron.core").send_until_cursor()
        end,
        desc = "Send until cursor",
      },
    },

    opts = function()
      local view = require("iron.view")
      local common = require("iron.fts.common")
      return {
        config = {
          scratch_repl = true,
          repl_definition = {
            ["python"] = {
              command = { "ipython", "--no-autoindent" },
              format = common.bracketed_paste_python,
              block_dividers = { "# %%", "#%%" },
            },
          },
          repl_open_cmd = view.split.vertical.botright("40%"),
          highlight_last = "IronLastSent",
          close_window_on_exit = true,
          buflisted = false,
        },
        highlight = { italic = true },
        ignore_blank_lines = true,
      }
    end,
  },

  {
    "GCBallesteros/jupytext.nvim",
    lazy = false,
    -- `opts` must be defined for this plugin (at least to `{}`).
    opts = {
      force_ft = "python.ipynb",
    },
  },

  {
    "GCBallesteros/NotebookNavigator.nvim",
    keys = {
      {
        "]k",
        function()
          require("notebook-navigator").move_cell("d")
        end,
        desc = "Next cell",
      },
      {
        "[k",
        function()
          require("notebook-navigator").move_cell("u")
        end,
        desc = "Prev cell",
      },
      {
        "<leader>ki",
        function()
          require("notebook-navigator").add_cell_below()
        end,
        desc = "Add cell below",
      },
      {
        "<leader>ko",
        function()
          require("notebook-navigator").add_cell_above()
        end,
        desc = "Add cell above",
      },
    },
    opts = {
      syntax_highlight = true,
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    ft = "python.ipynb",
  },
  {
    "neovim/nvim-lspconfig",
    ft = "python.ipynb",
    opts = {
      servers = {
        pyright = {
          filetypes = { "python", "python.ipynb" },
        },
      },
    },
  },
  {
    "nvim-mini/mini.ai",
    ft = "python.ipynb",
    opts = function(_, opts)
      opts.custom_textobjects = opts.custom_textobjects or {}
      -- Function is inlined instead of simpler `require("notebook-navigator").miniai_spec`
      -- to avoid unnecessary notebook-navigator loading on any filetype.
      -- (mini.ai is almost always loaded, and pulls navigator).
      -- Navigator complains when encounters unknown filetypes as well as pull iron.vim with itself.
      opts.custom_textobjects.k = function(opts)
        local cell_marker = "# %%"
        local start_line = vim.fn.search("^" .. cell_marker, "bcnW")

        -- Just in case the notebook is malformed and doesn't have a cell marker at the start.
        if start_line == 0 then
          start_line = 1
        else
          if opts == "i" then
            start_line = start_line + 1
          end
        end
        local end_line = vim.fn.search("^" .. cell_marker, "nW") - 1
        if end_line == -1 then
          end_line = vim.fn.line("$")
        end
        local last_col = math.max(vim.fn.getline(end_line):len(), 1)
        local from = { line = start_line, col = 1 }
        local to = { line = end_line, col = last_col }
        return { from = from, to = to }
      end
      return opts
    end,
  },

  -- https://github.com/kiyoon/jupynium.nvim (> 750 stars)
  --   A bit cumbersome setup with strict requirement on Firefox
  --   and non-nixpackaged jupynium python module counterpart.

  -- https://github.com/goerz/jupytext.nvim (> 90 stars)
  -- https://github.com/benlubas/molten-nvim (> 1100 stars)
  --    Combination of auto-conversion between ipynb and py files and interactive REPL.
  --    Setup is very cumbersome. At the end the problem was in a very slow performance.
  -- {
  --   "benlubas/molten-nvim",
  --   build = ":UpdateRemotePlugins",
  --   lazy = false,
  --   dependencies = { "3rd/image.nvim" },
  -- },
  -- {
  --   "3rd/image.nvim",
  --   event = "VeryLazy",
  --   -- `opts` must be defined for this plugin (at least to `{}`).
  --   opts = {
  --     processor = "magick_rock",
  --     -- https://github.com/benlubas/molten-nvim/blob/c1db39e78fe18559d8f2204bf5c4d476bdc80d3e/docs/Not-So-Quick-Start-Guide.md
  --     max_width = 120,
  --     max_height = 200,
  --     max_height_window_percentage = math.huge,
  --     max_width_window_percentage = math.huge,
  --     window_overlap_clear_enabled = true,
  --     window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
  --   },
  -- },
  -- {
  --   "GCBallesteros/jupytext.nvim",
  --   lazy = false,
  --   opts = {},
  -- },

  -- https://github.com/SUSTech-data/neopyter (> 150 stars)
  -- Eventually did not work.
  -- {
  --   "SUSTech-data/neopyter",
  --   lazy = false,
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "nvim-treesitter/nvim-treesitter",
  --     "AbaoFromCUG/websocket.nvim", -- for mode='direct'.
  --   },
  -- },

  -- https://github.com/ajbucci/ipynb.nvim (> 20 stars)
  -- Very buggy.
  --  One problem is regular termination of jupyter kernel with no apparent reason.
  --  Another is broken rendering of cells in some conditions.
  -- {
  --   "ajbucci/ipynb.nvim",
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --     "neovim/nvim-lspconfig",
  --     "folke/snacks.nvim", -- For inline images.
  --   },
  --   lazy = false,
  --   -- `opts` must be defined for this plugin (at least to `{}`).
  --   opts = {},
  -- },
  -- {
  --   "nvim-lualine/lualine.nvim",
  --   opts = function(_, opts)
  --     opts.sections.lualine_y = {
  --       {
  --         require("ipynb.kernel").statusline,
  --         cond = require("ipynb.kernel").statusline_visible,
  --         color = require("ipynb.kernel").statusline_color,
  --       },
  --     }
  --   end,
  -- },
}
