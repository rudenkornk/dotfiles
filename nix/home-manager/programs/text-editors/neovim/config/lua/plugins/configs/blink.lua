local M = {}

local kind_icons = {
  claude = " ",
  openai = " ",
  codestral = "󰬔 ",
  gemini = " ",
  Groq = "",
  Openrouter = "󱂇 ",
  Ollama = "󰳆 ",
  ["Llama.cpp"] = "󰳆 ",
  Deepseek = "󱢴 ",
  qwen = " ",
}

M.dependencies = {
  "Kaiser-Yang/blink-cmp-dictionary",
  "Saghen/blink.compat",
  "andersevenrud/cmp-tmux",
  "bydlw98/blink-cmp-env",
  "hrsh7th/cmp-emoji",
}

M.opts = {
  sources = {
    compat = { "emoji", "tmux" },
    default = {
      "lsp",
      "path",
      "snippets",
      "buffer",
      "minuet",
      "env",
      "dictionary",
    },
    providers = {
      dictionary = {
        name = "Dict",
        module = "blink-cmp-dictionary",
        min_keyword_length = 4, -- Start matching with 4+ letters.
        score_offset = -40,
        opts = {
          dictionary_files = { vim.env.WORDLIST },
        },
      },
      env = {
        name = "Env",
        module = "blink-cmp-env",
      },
      buffer = {
        score_offset = -10,
      },
      tmux = {
        name = "tmux",
        score_offset = -30,
        opts = { label = " ", all_panes = true },
      },
      minuet = {
        name = "minuet",
        module = "minuet.blink",
        async = true,
        -- Should match `minuet.config.request_timeout * 1000`,
        -- since `minuet.config.request_timeout` is in seconds.
        timeout_ms = 3000,
        score_offset = 10,
      },
    },
  },
  appearance = {
    kind_icons = kind_icons,
  },
  completion = {
    list = {
      -- For some reason enabled `auto_insert` suddenly closes the completion menu,
      -- after pressed down `select_next`/`select_prev` keymaps for ~1000ms.
      selection = { auto_insert = false },
      cycle = { from_bottom = false, from_top = false },
    },
    documentation = { auto_show_delay_ms = 0 },
  },
  keymap = {
    ["<C-k>"] = { "show", "show_documentation", "hide_documentation" },
    ["<C-d>"] = {
      function(cmp)
        for _ = 1, 5 do
          cmp.select_next()
        end
      end,
    },
    ["<C-u>"] = {
      function(cmp)
        for _ = 1, 5 do
          cmp.select_prev()
        end
      end,
    },
  },
}

return M
