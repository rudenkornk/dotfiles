local M = {}

M.disabled = {
  n = {
    ["<C-h>"] = "", -- Unmap pane switch. This will be managed by Navigator.
    ["<C-j>"] = "", -- Unmap pane switch. This will be managed by Navigator.
    ["<C-k>"] = "", -- Unmap pane switch. This will be managed by Navigator.
    ["<C-l>"] = "", -- Unmap pane switch. This will be managed by Navigator.
    ["<TAB>"] = "", -- Unmap buffer cycling. This interferes with <C-i> behaviour.
    ["<S-b>"] = "", -- Unmap creating new buffer. This interferes with default <S-b> behaviour.
    ["<leader>tp"] = "", -- Unmap tabs cycling. Instead, assign buffers cycling to these keys.
    ["<leader>tn"] = "", -- Unmap tabs cycling. Instead, assign buffers cycling to these keys.
  },
}

M.custom = {
  n = {
    ["<C-g>"] = { "a<C-^><ESC>", "וּ Toggle layout" },
    ["<leader>vc"] = { "<CMD>%s/\\([^ ]\\)\\s\\+/\\1 /g | noh <CR>", " Clear extra spaces" },
    ["<leader>db"] = { ":Break<CR>", " Set breakpoint" },
    ["<leader>dr"] = { ":call TermDebugSendCommand('run')<CR>", " Run" },
    ["<leader>dn"] = { ":call TermDebugSendCommand('next')<CR>", " Step over" },
    ["<leader>ds"] = { ":call TermDebugSendCommand('step')<CR>", " Step into" },
    ["<leader>df"] = { ":call TermDebugSendCommand('finish')<CR>", " Step out" },
    ["<leader>dc"] = { ":call TermDebugSendCommand('continue')<CR>", "懶 Continue" },
    ["<leader>du"] = { ":call TermDebugSendCommand('up')<CR>", " Up stack" },
    ["<leader>dd"] = { ":call TermDebugSendCommand('down')<CR>", " Down stack" },
    ["<leader>dt"] = { ":call TermDebugSendCommand('backtrace')<CR>", " Show backtrace" },
    ["<A-n>"] = { "<CMD>lua require('illuminate').next_reference{wrap=true}<CR>", " Next reference" },
    ["<A-p>"] = { "<CMD>lua require('illuminate').next_reference{reverse=true,wrap=true}<CR>", " Previous reference" },

    ["<leader>tp"] = { "<CMD> Tbufnext <CR>", "  goto next buffer" },
    ["<leader>tn"] = { "<CMD> Tbufprev <CR>", "  goto prev buffer" },

    ["<C-w>h"] = { "<CMD>NavigatorLeft<CR>", " Left pane" },
    ["<C-w>j"] = { "<CMD>NavigatorDown<CR>", " Lower pane" },
    ["<C-w>k"] = { "<CMD>NavigatorUp<CR>", " Upper pane" },
    ["<C-w>l"] = { "<CMD>NavigatorRight<CR>", " Right pane" },
    ["<C-w>p"] = { "<CMD>NavigatoPrevious<CR>", " Previous pane" },
  },

  i = {
    ["<C-g>"] = { "<C-^>", "וּ Toggle layout" },
    ["<A-n>"] = { "<cmd>lua require('illuminate').next_reference{wrap=true}<CR>", " Next reference" },
    ["<A-p>"] = { "<cmd>lua require('illuminate').next_reference{reverse=true,wrap=true}<CR>", " Previous reference" },
  },
  x = {
    ["<leader>vc"] = { "<CMD>s/\\([^ ]\\)\\s\\+/\\1 /g | noh <CR>", " Clear extra spaces" },
    ["<leader>vt"] = { "<CMD>s/\\([^ ]\\)\\s\\+/\\1 /g | noh | '<,'>Tabularize /\\s\\+/l0<CR>", "璘 Tabularize" },
    ["<leader>vs"] = { ":sort<CR>", " Sort" },
  },
}

return M
