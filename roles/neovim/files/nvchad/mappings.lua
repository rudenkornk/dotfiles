-- NcChad free leader keys:
-- <leader>a <leader>A
-- <leader>B
-- <leader>C
-- <leader>d
-- <leader>E
-- <leader>F
-- <leader>G
-- <leader>h <leader>H
-- <leader>i <leader>I
-- <leader>j <leader>J
-- <leader>k <leader>K
-- <leader>L
-- <leader>m <leader>M
-- <leader>N
-- <leader>o <leader>O
-- <leader>P
-- <leader>q <leader>Q
-- <leader>R
-- <leader>s <leader>S
-- <leader>T
-- <leader>U
-- <leader>V
-- <leader>W
-- <leader>X
-- <leader>y <leader>Y
-- <leader>z <leader>Z

local M = {}

local function termcodes(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

M.aerial = {
  n = {
    ["<leader>o"] = { "<CMD>AerialToggle<CR>", "ƒ  Code outline" },
  },
}

M.code_action_menu = {
  n = {
    ["<leader>ca"] = { "<CMD>CodeActionMenu<CR>", "  code actions" },
  },
}

M.disabled = {
  n = {
    ["<TAB>"] = "", -- Unmap buffer cycling. This interferes with <C-i> behaviour.
    ["<leader>h"] = "", -- Unmap horizontal terminal (use <A-h>)
    ["<leader>v"] = "", -- Unmap vertical terminal (use <A-v>)
    ["<leader>x"] = "", -- Unmap closing buffer (map <leader>q instead)
  },
}

M.goto_preview = {
  n = {
    ["gpd"] = { "<CMD>lua require('goto-preview').goto_preview_definition()<CR>", "  preview definition" },
    ["gpt"] = {
      "<CMD>lua require('goto-preview').goto_preview_type_definition()<CR>",
      "  preview type definition",
    },
    ["gpi"] = { "<CMD>lua require('goto-preview').goto_preview_implementation()<CR>", "  preview implementation" },
    ["gq"] = { "<CMD>lua require('goto-preview').close_all_win()<CR>", "  close previews" },
    -- does not work
    ["gpr"] = { "<CMD>lua require('goto-preview').goto_preview_references()<CR>", "  preview references" },
  },
}

M.illuminate = {
  i = {
    ["<A-n>"] = { "<cmd>lua require('illuminate').next_reference{wrap=true}<CR>", "  Next reference" },
    ["<A-p>"] = {
      "<cmd>lua require('illuminate').next_reference{reverse=true,wrap=true}<CR>",
      "  Previous reference",
    },
  },
  n = {
    ["<A-n>"] = { "<CMD>lua require('illuminate').next_reference{wrap=true}<CR>", "  Next reference" },
    ["<A-p>"] = {
      "<CMD>lua require('illuminate').next_reference{reverse=true,wrap=true}<CR>",
      "  Previous reference",
    },
  },
}

M.layout = {
  n = {
    ["<C-g>"] = { "a<C-^><ESC>", "וּ  Toggle layout" },
  },
  i = {
    ["<C-g>"] = { "<C-^>", "וּ  Toggle layout" },
  },
}

M.lspconfig = {
  n = {
    ["]d"] = {
      function()
        vim.diagnostic.goto_next()
      end,
      "  goto_next",
    },
    ["gt"] = {
      function()
        vim.lsp.buf.type_definition()
      end,
      "  type definition",
    },
  },
}

M.navigator = {
  c = {
    ["<C-h>"] = { "<CMD>NavigatorLeft<CR>", "  Left pane" },
    ["<C-j>"] = { "<CMD>NavigatorDown<CR>", "  Lower pane" },
    ["<C-k>"] = { "<CMD>NavigatorUp<CR>", "  Upper pane" },
    ["<C-l>"] = { "<CMD>NavigatorRight<CR>", "  Right pane" },
  },
  n = {
    ["<C-h>"] = { "<CMD>NavigatorLeft<CR>", "  Left pane" },
    ["<C-j>"] = { "<CMD>NavigatorDown<CR>", "  Lower pane" },
    ["<C-k>"] = { "<CMD>NavigatorUp<CR>", "  Upper pane" },
    ["<C-l>"] = { "<CMD>NavigatorRight<CR>", "  Right pane" },
  },
  t = {
    ["<C-h>"] = { "<CMD>NavigatorLeft<CR>", "  Left pane" },
    ["<C-j>"] = { "<CMD>NavigatorDown<CR>", "  Lower pane" },
    ["<C-k>"] = { "<CMD>NavigatorUp<CR>", "  Upper pane" },
    ["<C-l>"] = { "<CMD>NavigatorRight<CR>", "  Right pane" },
  },
}

M.nvterm = {
  t = {
    ["<A-f>"] = {
      function()
        require("nvterm.terminal").toggle("float")
      end,
      "  toggle floating term",
    },
  },

  n = {
    ["<A-f>"] = {
      function()
        require("nvterm.terminal").toggle("float")
      end,
      "  toggle floating term",
    },
  },
}

M.symbols_outline = {
  n = {
    ["<leader>s"] = { "<CMD>SymbolsOutline<CR>", "  symbols outline" },
  },
}

M.tabufline = {
  n = {
    ["<leader>tp"] = { "<CMD> Tbufnext <CR>", "  goto next buffer" },
    ["<leader>tn"] = { "<CMD> Tbufprev <CR>", "  goto prev buffer" },

    -- close buffer + hide terminal buffer
    ["<leader>d"] = {
      function()
        require("nvchad_ui.tabufline").close_buffer()
      end,
      "close buffer",
    },
  },
}

M.termdebug = {
  n = {
    ["<A-g>"] = { "<CMD>Termdebug<CR>i", "ﴫ  Run gdb" },
    ["<A-r>"] = { "<CMD>call TermDebugSendCommand('run')<CR>", "  Run" },
    ["<A-b>"] = { "<CMD>Break<CR>", "  Set breakpoint" },
    ["<A-j>"] = { "<CMD>call TermDebugSendCommand('next')<CR>", "  Step over" },
    ["<A-i>"] = { "<CMD>call TermDebugSendCommand('step')<CR>", "  Step into" },
    ["<A-o>"] = { "<CMD>call TermDebugSendCommand('finish')<CR>", "  Step out" },
    ["<A-c>"] = { "<CMD>call TermDebugSendCommand('continue')<CR>", "懶  Continue" },
    ["<A-u>"] = { "<CMD>call TermDebugSendCommand('up')<CR>", "  Up stack" },
    ["<A-d>"] = { "<CMD>call TermDebugSendCommand('down')<CR>", "  Down stack" },
  },
  t = {
    ["<A-r>"] = { "<CMD>call TermDebugSendCommand('run')<CR>", "  Run" },
    ["<A-j>"] = { "<CMD>call TermDebugSendCommand('next')<CR>", "  Step over" },
    ["<A-i>"] = { "<CMD>call TermDebugSendCommand('step')<CR>", "  Step into" },
    ["<A-k>"] = { "<CMD>call TermDebugSendCommand('finish')<CR>", "  Step out" },
    ["<A-c>"] = { "<CMD>call TermDebugSendCommand('continue')<CR>", "懶  Continue" },
    ["<A-u>"] = { "<CMD>call TermDebugSendCommand('up')<CR>", "  Up stack" },
    ["<A-d>"] = { "<CMD>call TermDebugSendCommand('down')<CR>", "  Down stack" },
    ["<ESC>"] = { termcodes("<C-\\><C-N>"), "  escape terminal mode" },
  },
}

M.trouble = {
  n = {
    ["<leader>q"] = { "<CMD>TroubleToggle<CR>", "  diagnostic list" },
    ["gr"] = { "<CMD>TroubleToggle lsp_references<CR>", "  lsp references" },
    ["<leader>xw"] = { "<CMD>TroubleToggle workspace_diagnostics<CR>", "  workspace diagnostic list" },
    ["<leader>xd"] = { "<CMD>TroubleToggle document_diagnostics<CR>", "  document diagnostic list" },
    ["<leader>xq"] = { "<CMD>TroubleToggle quickfix<CR>", "  quickfix list" },
    ["<leader>xl"] = { "<CMD>TroubleToggle loclist<CR>", "  location list" },
  },
}

M.utils = {
  n = {
    ["<leader>vc"] = { "<CMD>%s/\\([^ ]\\)\\s\\+/\\1 /g | noh <CR>", "  Clear extra spaces" },
  },
  x = {
    ["<leader>vc"] = { "<CMD>s/\\([^ ]\\)\\s\\+/\\1 /g | noh <CR>", "  Clear extra spaces" },
    ["<leader>vt"] = { "<CMD>s/\\([^ ]\\)\\s\\+/\\1 /g | noh | '<,'>Tabularize /\\s\\+/l0<CR>", "璘  Tabularize" },
    ["<leader>vs"] = { ":sort i<CR>", "  Sort" },
    ["<leader>vS"] = { ":sort<CR>", "  Sort case sensitive" },
  },
}
vim.o.pastetoggle = "<C-q>"
vim.cmd([[ cnoremap <C-a> <HOME>]])

return M
