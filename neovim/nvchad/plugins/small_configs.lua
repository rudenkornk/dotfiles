M = {}

M.aerial = {
  cmd = {
    "Aerial*",
  },
  config = function()
    require("aerial").setup()
  end,
}

M.better_escape = {
  event = "InsertEnter",
  config = function()
    require("better_escape").setup()
  end,
}

M.cmp_cmdline = {
  after = "nvim-cmp",
}

M.cmp_git = {
  after = "nvim-cmp",
  requires = "nvim-lua/plenary.nvim",
  config = function()
    require("cmp_git").setup()
  end,
}

M.cmp_rg = {
  after = "nvim-cmp",
}

M.cmp_tabnine = {
  after = "nvim-cmp",
  module = "cmp_tabnine",
  run = "./install.sh",
  config = function()
    local tabnine = require("cmp_tabnine.config")
    tabnine:setup({
      max_num_results = 4,
      show_prediction_strength = true,
    })
  end,
}

M.cmp_tmux = {
  after = "nvim-cmp",
}

M.code_action_menu = {
  cmd = "CodeActionMenu",
}

M.copilot_cmp = {
  module = "copilot_cmp",
}

M.copilot = {
  after = "nvim-cmp",
  config = function()
    require("copilot").setup()
  end,
}

M.friendly_snippets = {
  -- The only purpose of this config is to trigger nvim-cmp on CmdlineEnter event
  event = {
    "InsertEnter",
    "CmdlineEnter",
  },
}

M.gitsigns = {
  -- fix "missing gitsigns" error in non-gitcommit files
  after = "nvim-lspconfig",
}

M.goto_preview = {
  module = "goto-preview",
  config = function()
    require("goto-preview").setup()
  end,
}

M.illuminate = {
  module = "illuminate",
}

M.indent_blankline = {
  show_current_context_start = false,
}

M.navigator = {
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
}

M.surround = {
  keys = { "c", "d", "y" },
  config = function()
    require("nvim-surround").setup()
  end,
}

M.symbols_outline = {
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
}

M.tabular = {
  cmd = "Tabularize",
}

M.telescope = {
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
}

M.trouble = {
  cmd = {
    "Trouble",
    "TroubleClose",
    "TroubleToggle",
    "TroubleRefresh",
  },
  config = function()
    require("trouble").setup()
  end,
}

M.vim_tmux_clipboard = {}

return M
