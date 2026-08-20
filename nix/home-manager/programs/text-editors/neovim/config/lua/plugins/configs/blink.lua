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
        max_items = 2,
        opts = {
          dictionary_files = { vim.env.WORDLIST },
          -- Fix for weird spurious bug where complete items appear in one line with
          -- `^@` chars in cmp menu and make `vim.fn.strchars` fail with `E976`.
          separate_output = function(output)
            local words = {}
            for word in output:gmatch("[^%z\r\n]+") do
              words[#words + 1] = word
            end
            return words
          end,
        },
      },
      env = {
        name = "Env",
        module = "blink-cmp-env",
        max_items = 5,
      },
      buffer = {
        score_offset = -10,
        max_items = 2,
      },
      tmux = {
        name = "tmux",
        score_offset = -30,
        max_items = 2,
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
