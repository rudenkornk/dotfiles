local M = {}

local function termcodes(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

M.disabled = {
  n = {
    ["<TAB>"] = "", -- Unmap buffer cycling. This interferes with <C-i> behaviour.
    ["<S-b>"] = "", -- Unmap creating new buffer. This interferes with default <S-b> behaviour.
  },
}

M.utils = {
  n = {
    ["<leader>vc"] = { "<CMD>%s/\\([^ ]\\)\\s\\+/\\1 /g | noh <CR>", " Clear extra spaces" },
  },
  x = {
    ["<leader>vc"] = { "<CMD>s/\\([^ ]\\)\\s\\+/\\1 /g | noh <CR>", " Clear extra spaces" },
    ["<leader>vt"] = { "<CMD>s/\\([^ ]\\)\\s\\+/\\1 /g | noh | '<,'>Tabularize /\\s\\+/l0<CR>", "璘 Tabularize" },
    ["<leader>vs"] = { ":sort<CR>", " Sort" },
  },
}
vim.o.pastetoggle = "<C-q>"
vim.cmd([[ cnoremap <C-a> <HOME>]])

M.layout = {
  n = {
    ["<C-g>"] = { "a<C-^><ESC>", "וּ Toggle layout" },
  },
  i = {
    ["<C-g>"] = { "<C-^>", "וּ Toggle layout" },
  },
}

M.tabufline = {
  n = {
    ["<leader>tp"] = { "<CMD> Tbufnext <CR>", "  goto next buffer" },
    ["<leader>tn"] = { "<CMD> Tbufprev <CR>", "  goto prev buffer" },
  },
}

M.navigator = {
  n = {
    ["<C-h>"] = { "<CMD>NavigatorLeft<CR>", " Left pane" },
    ["<C-j>"] = { "<CMD>NavigatorDown<CR>", " Lower pane" },
    ["<C-k>"] = { "<CMD>NavigatorUp<CR>", " Upper pane" },
    ["<C-l>"] = { "<CMD>NavigatorRight<CR>", " Right pane" },
  },
  t = {
    ["<C-h>"] = { "<CMD>NavigatorLeft<CR>", " Left pane" },
    ["<C-j>"] = { "<CMD>NavigatorDown<CR>", " Lower pane" },
    ["<C-k>"] = { "<CMD>NavigatorUp<CR>", " Upper pane" },
    ["<C-l>"] = { "<CMD>NavigatorRight<CR>", " Right pane" },
  },
}

M.termdebug = {
  n = {
    ["<A-g>"] = { "<CMD>Termdebug<CR>i", "ﴫ Run gdb" },
    ["<A-r>"] = { "<CMD>call TermDebugSendCommand('run')<CR>", " Run" },
    ["<A-b>"] = { "<CMD>Break<CR>", " Set breakpoint" },
    ["<A-j>"] = { "<CMD>call TermDebugSendCommand('next')<CR>", " Step over" },
    ["<A-k>"] = { "<CMD>call TermDebugSendCommand('step')<CR>", " Step into" },
    ["<A-o>"] = { "<CMD>call TermDebugSendCommand('finish')<CR>", " Step out" },
    ["<A-c>"] = { "<CMD>call TermDebugSendCommand('continue')<CR>", "懶 Continue" },
    ["<A-u>"] = { "<CMD>call TermDebugSendCommand('up')<CR>", " Up stack" },
    ["<A-d>"] = { "<CMD>call TermDebugSendCommand('down')<CR>", " Down stack" },
  },
  t = {
    ["<A-r>"] = { "<CMD>call TermDebugSendCommand('run')<CR>", " Run" },
    ["<A-j>"] = { "<CMD>call TermDebugSendCommand('next')<CR>", " Step over" },
    ["<A-k>"] = { "<CMD>call TermDebugSendCommand('step')<CR>", " Step into" },
    ["<A-o>"] = { "<CMD>call TermDebugSendCommand('finish')<CR>", " Step out" },
    ["<A-c>"] = { "<CMD>call TermDebugSendCommand('continue')<CR>", "懶 Continue" },
    ["<A-u>"] = { "<CMD>call TermDebugSendCommand('up')<CR>", " Up stack" },
    ["<A-d>"] = { "<CMD>call TermDebugSendCommand('down')<CR>", " Down stack" },
    ["<ESC>"] = { termcodes("<C-\\><C-N>"), "   escape terminal mode" },
  },
}

M.illuminate = {
  n = {
    ["<A-n>"] = { "<CMD>lua require('illuminate').next_reference{wrap=true}<CR>", " Next reference" },
    ["<A-p>"] = {
      "<CMD>lua require('illuminate').next_reference{reverse=true,wrap=true}<CR>",
      " Previous reference",
    },
  },
  i = {
    ["<A-n>"] = { "<cmd>lua require('illuminate').next_reference{wrap=true}<CR>", " Next reference" },
    ["<A-p>"] = {
      "<cmd>lua require('illuminate').next_reference{reverse=true,wrap=true}<CR>",
      " Previous reference",
    },
  },
}

return M
