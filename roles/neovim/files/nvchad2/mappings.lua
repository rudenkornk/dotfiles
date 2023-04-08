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

M.dial = {
  n = {
    ["<C-a>"] = {
      function()
        return require("dial.map").inc_normal()
      end,
      opts = { expr = true },
    },
    ["<C-x>"] = {
      function()
        return require("dial.map").dec_normal()
      end,
      opts = { expr = true },
    },
  },
  v = {
    ["<C-a>"] = {
      function()
        return require("dial.map").inc_visual()
      end,
      opts = { expr = true },
    },
    ["<C-x>"] = {
      function()
        return require("dial.map").dec_visual()
      end,
      opts = { expr = true },
    },
    ["g<C-a>"] = {
      function()
        return require("dial.map").inc_gvisual()
      end,
      opts = { expr = true },
    },
    ["g<C-x>"] = {
      function()
        return require("dial.map").dec_gvisual()
      end,
      opts = { expr = true },
    },
  },
}

M.disabled = {
  t = {
    ["<A-f>"] = "", -- Unmap terminals (use tmux)
    ["<A-i>"] = "", -- Unmap terminals (use tmux)
    ["<A-v>"] = "", -- Unmap terminals (use tmux)
  },
  n = {
    ["<A-f>"] = "", -- Unmap terminals (use tmux)
    ["<A-i>"] = "", -- Unmap terminals (use tmux)
    ["<A-v>"] = "", -- Unmap terminals (use tmux)
    ["<C-h>"] = "", -- Unmap navigation (overriding with tmux)
    ["<C-j>"] = "", -- Unmap navigation (overriding with tmux)
    ["<C-k>"] = "", -- Unmap navigation (overriding with tmux)
    ["<C-l>"] = "", -- Unmap navigation (overriding with tmux)
    ["<leader>v"] = "", -- Unmap terminals (use tmux)
    ["<leader>x"] = "", -- Unmap closing buffer (map <leader>d instead)
    ["<TAB>"] = "", -- Unmap buffer cycling. This interferes with <C-i> behaviour.
  },
}

M.goto_preview = {
  n = {
    ["gpd"] = {
      function()
        require("goto-preview").goto_preview_definition()
      end,
      "  preview definition",
    },
    ["gpt"] = {
      function()
        require("goto-preview").goto_preview_type_definition()
      end,
      "  preview type definition",
    },
    ["gpi"] = {
      function()
        require("goto-preview").goto_preview_implementation()
      end,
      "  preview implementation",
    },
    ["gq"] = {
      function()
        require("goto-preview").close_all_win()
      end,
      "  close previews",
    },
    -- does not work
    ["gpr"] = {
      function()
        require("goto-preview").goto_preview_references()
      end,
      "  preview references",
    },
  },
}

M.hop = {
  n = {
    ["f"] = {
      function()
        require("hop").hint_char1({ direction = nil })
      end,
      "hop char",
    },
    ["t"] = {
      function()
        require("hop").hint_char1({ direction = nil, hint_offset = -1 })
      end,
      "hop char",
    },
    ["F"] = {
      function()
        require("hop").hint_words({ direction = nil, hint_offset = -1 })
      end,
      "hop word",
    },
  },
  v = {
    ["f"] = {
      function()
        require("hop").hint_char1({ direction = nil })
      end,
      "hop char",
    },
    ["t"] = {
      function()
        require("hop").hint_char1({ direction = nil, hint_offset = -1 })
      end,
      "hop char",
    },
    ["F"] = {
      function()
        require("hop").hint_words({ direction = nil, hint_offset = -1 })
      end,
      "hop word",
    },
  },
}

M.spider = {
  n = {
    ["w"] = {
      function()
        require("spider").motion("w")
      end,
    },
    ["e"] = {
      function()
        require("spider").motion("e")
      end,
    },
    ["b"] = {
      function()
        require("spider").motion("b")
      end,
    },
    ["ge"] = {
      function()
        require("spider").motion("ge")
      end,
    },
  },
  x = {
    ["w"] = {
      function()
        require("spider").motion("w")
      end,
    },
    ["e"] = {
      function()
        require("spider").motion("e")
      end,
    },
    ["b"] = {
      function()
        require("spider").motion("b")
      end,
    },
    ["ge"] = {
      function()
        require("spider").motion("ge")
      end,
    },
  },
}

M.illuminate = {
  i = {
    ["<A-n>"] = {
      function()
        require("illuminate").next_reference({ wrap = true })
      end,
      "  next reference",
    },
    ["<A-p>"] = {
      function()
        require("illuminate").next_reference({ reverse = true, wrap = true })
      end,
      "  previous reference",
    },
  },
  n = {
    ["<A-n>"] = {
      function()
        require("illuminate").next_reference({ wrap = true })
      end,
      "  next reference",
    },
    ["<A-p>"] = {
      function()
        require("illuminate").next_reference({ reverse = true, wrap = true })
      end,
      "  previous reference",
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

M.nvterm = {
  t = {
    ["<A-v>"] = {
      function()
        require("nvterm.terminal").toggle("float")
      end,
      "  toggle floating term",
    },
  },

  n = {
    ["<A-v>"] = {
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

M.syntax_tree_surfer = {
  n = {
    ["<A-k>"] = {
      function()
        require("syntax-tree-surfer")
        vim.opt.opfunc = "v:lua.STSSwapUpNormal_Dot"
        return "g@l"
      end,
      opts = { expr = true },
    },
    ["<A-j>"] = {
      function()
        require("syntax-tree-surfer")
        vim.opt.opfunc = "v:lua.STSSwapDownNormal_Dot"
        return "g@l"
      end,
      opts = { expr = true },
    },
    ["<A-l>"] = {
      function()
        require("syntax-tree-surfer")
        vim.opt.opfunc = "v:lua.STSSwapCurrentNodeNextNormal_Dot"
        return "g@l"
      end,
      opts = { expr = true },
    },
    ["<A-h>"] = {
      function()
        require("syntax-tree-surfer")
        vim.opt.opfunc = "v:lua.STSSwapCurrentNodePrevNormal_Dot"
        return "g@l"
      end,
      opts = { expr = true },
    },
    ["T"] = {
      function()
        require("syntax-tree-surfer").targeted_jump({
          "if_statement",
          "else_clause",
          "else_statement",
          "elseif_statement",
          "for_statement",
          "while_statement",
          "switch_statement",
          "function_definition",
          "variable_declaration",
        })
      end,
    },
  },
  v = {
    ["<A-j>"] = { "<CMD>STSSwapNextVisual<CR>" },
    ["<A-k>"] = { "<CMD>STSSwapPrevVisual<CR>" },
    ["T"] = {
      function()
        require("syntax-tree-surfer").targeted_jump({
          "if_statement",
          "else_clause",
          "else_statement",
          "elseif_statement",
          "for_statement",
          "while_statement",
          "switch_statement",
          "function_definition",
          "variable_declaration",
        })
      end,
    },
    [";"] = { "<CMD>STSSelectParentNode<CR>" },
    ["i;"] = { "<CMD>STSSelectChildNode<CR>" },
  },
  o = {
    ["<A-k>"] = { "<CMD>STSSwapPrevVisual<CR>" },
    ["<A-j>"] = { "<CMD>STSSwapNextVisual<CR>" },
    ["F"] = {
      function()
        require("syntax-tree-surfer").targeted_jump({
          "if_statement",
          "else_clause",
          "else_statement",
          "elseif_statement",
          "for_statement",
          "while_statement",
          "switch_statement",
          "function_definition",
          "variable_declaration",
        })
      end,
    },
  },
}

M.tabufline = {
  n = {
    ["<leader>tp"] = {
      function()
        require("nvchad_ui.tabufline").tabuflineNext()
      end,
      "  goto next buffer",
    },
    ["<leader>tn"] = {
      function()
        require("nvchad_ui.tabufline").tabuflinePrev()
      end,
      "  goto prev buffer",
    },

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
    ["<A-f>"] = { "<CMD>call TermDebugSendCommand('next')<CR>", "  Step over" },
    ["<A-i>"] = { "<CMD>call TermDebugSendCommand('step')<CR>", "  Step into" },
    ["<A-o>"] = { "<CMD>call TermDebugSendCommand('finish')<CR>", "  Step out" },
    ["<A-c>"] = { "<CMD>call TermDebugSendCommand('continue')<CR>", "懶  Continue" },
    ["<A-u>"] = { "<CMD>call TermDebugSendCommand('up')<CR>", "  Up stack" },
    ["<A-d>"] = { "<CMD>call TermDebugSendCommand('down')<CR>", "  Down stack" },
  },
  t = {
    ["<A-r>"] = { "<CMD>call TermDebugSendCommand('run')<CR>", "  Run" },
    ["<A-f>"] = { "<CMD>call TermDebugSendCommand('next')<CR>", "  Step over" },
    ["<A-i>"] = { "<CMD>call TermDebugSendCommand('step')<CR>", "  Step into" },
    ["<A-o>"] = { "<CMD>call TermDebugSendCommand('finish')<CR>", "  Step out" },
    ["<A-c>"] = { "<CMD>call TermDebugSendCommand('continue')<CR>", "懶  Continue" },
    ["<A-u>"] = { "<CMD>call TermDebugSendCommand('up')<CR>", "  Up stack" },
    ["<A-d>"] = { "<CMD>call TermDebugSendCommand('down')<CR>", "  Down stack" },
    ["<ESC>"] = { termcodes("<C-\\><C-N>"), "  escape terminal mode" },
  },
}

M.tmux = {
  c = {
    ["<C-h>"] = {
      function()
        require("tmux").move_left()
      end,
      "  Left pane",
    },
    ["<C-j>"] = {
      function()
        require("tmux").move_bottom()
      end,
      "  Lower pane",
    },
    ["<C-k>"] = {
      function()
        require("tmux").move_top()
      end,
      "  Upper pane",
    },
    ["<C-l>"] = {
      function()
        require("tmux").move_right()
      end,
      "  Right pane",
    },
    ["<A-x>h"] = {
      function()
        require("tmux").resize_left()
      end,
    },
    ["<A-x>j"] = {
      function()
        require("tmux").resize_bottom()
      end,
    },
    ["<A-x>k"] = {
      function()
        require("tmux").resize_top()
      end,
    },
    ["<A-x>l"] = {
      function()
        require("tmux").resize_right()
      end,
    },
  },
  n = {
    ["<C-h>"] = {
      function()
        require("tmux").move_left()
      end,
      "  Left pane",
    },
    ["<C-j>"] = {
      function()
        require("tmux").move_bottom()
      end,
      "  Lower pane",
    },
    ["<C-k>"] = {
      function()
        require("tmux").move_top()
      end,
      "  Upper pane",
    },
    ["<C-l>"] = {
      function()
        require("tmux").move_right()
      end,
      "  Right pane",
    },
    ["<A-x>h"] = {
      function()
        require("tmux").resize_left()
      end,
    },
    ["<A-x>j"] = {
      function()
        require("tmux").resize_bottom()
      end,
    },
    ["<A-x>k"] = {
      function()
        require("tmux").resize_top()
      end,
    },
    ["<A-x>l"] = {
      function()
        require("tmux").resize_right()
      end,
    },
  },
  t = {
    ["<C-h>"] = {
      function()
        require("tmux").move_left()
      end,
      "  Left pane",
    },
    ["<C-j>"] = {
      function()
        require("tmux").move_bottom()
      end,
      "  Lower pane",
    },
    ["<C-k>"] = {
      function()
        require("tmux").move_top()
      end,
      "  Upper pane",
    },
    ["<C-l>"] = {
      function()
        require("tmux").move_right()
      end,
      "  Right pane",
    },
    ["<A-x>h"] = {
      function()
        require("tmux").resize_left()
      end,
    },
    ["<A-x>j"] = {
      function()
        require("tmux").resize_bottom()
      end,
    },
    ["<A-x>k"] = {
      function()
        require("tmux").resize_top()
      end,
    },
    ["<A-x>l"] = {
      function()
        require("tmux").resize_right()
      end,
    },
  },
  v = {
    ["<C-h>"] = {
      function()
        require("tmux").move_left()
      end,
      "  Left pane",
    },
    ["<C-j>"] = {
      function()
        require("tmux").move_bottom()
      end,
      "  Lower pane",
    },
    ["<C-k>"] = {
      function()
        require("tmux").move_top()
      end,
      "  Upper pane",
    },
    ["<C-l>"] = {
      function()
        require("tmux").move_right()
      end,
      "  Right pane",
    },
    ["<A-x>h"] = {
      function()
        require("tmux").resize_left()
      end,
    },
    ["<A-x>j"] = {
      function()
        require("tmux").resize_bottom()
      end,
    },
    ["<A-x>k"] = {
      function()
        require("tmux").resize_top()
      end,
    },
    ["<A-x>l"] = {
      function()
        require("tmux").resize_right()
      end,
    },
  },
}

M.trouble = {
  n = {
    ["<leader>q"] = { "<CMD>TroubleToggle<CR>", "  diagnostic list" },
    ["gr"] = { "<CMD>TroubleToggle lsp_references<CR>", "  lsp references" },
  },
}

M.utils = {
  n = {
    ["<leader>vc"] = { "<CMD>%s/\\([^ ]\\)\\s\\+/\\1 /g | noh <CR>", "  Clear extra spaces" },
    ["<C-e>"] = { "4<C-e>", "scroll several lines" },
    ["<C-y>"] = { "4<C-y>", "scroll several lines" },
    ["<C-z>"] = {
      function()
        -- do nothing
      end,
    },
  },
  x = {
    ["<C-e>"] = { "4<C-e>", "scroll several lines" },
    ["<C-y>"] = { "4<C-y>", "scroll several lines" },
    ["<leader>vc"] = { "<CMD>s/\\([^ ]\\)\\s\\+/\\1 /g | noh <CR>", "  Clear extra spaces" },
    ["<leader>vt"] = { "<CMD>s/\\([^ ]\\)\\s\\+/\\1 /g | noh | '<,'>Tabularize /\\s\\+/l0<CR>", "璘  Tabularize" },
    ["<leader>vs"] = { ":sort i<CR>", "  Sort" },
    ["<leader>vS"] = { ":sort<CR>", "  Sort case sensitive" },
  },
}
vim.o.pastetoggle = "<C-q>"
vim.cmd([[ cnoremap <C-a> <HOME>]])

return M
