local M = {}

local kind_icons = {
  claude = " ",
  openai = " ",
  codestral = "󰬔 ",
  gemini = " ",
  Groq = "",
  Openrouter = "󱂇 ",
  Ollama = "󰳆 ",
  ["Llama.cpp"] = "󰳆 ",
  Deepseek = "󱢴 ",
  qwen = " ",
}

M.dependencies = {
  "Saghen/blink.compat",
  "andersevenrud/cmp-tmux",
  "hrsh7th/cmp-emoji",
}

-- `internet` as an antonym for `intranet`.
local internet_providers = {
  supermaven = {
    score_offset = 15,
  },
  copilot = {
    score_offset = 20,
  },
}
local maybe_internet_providers = os.getenv("USERKIND") == "default" and internet_providers or {}

M.opts = {
  sources = {
    compat = { "emoji", "tmux" },
    default = {
      "lsp",
      "path",
      "snippets",
      "buffer",
      "avante",
      "minuet",
    },
    providers = vim.tbl_extend("error", {
      tmux = {
        name = "tmux",
        score_offset = -100,
        opts = { label = " ", all_panes = true },
      },
      minuet = {
        name = "minuet",
        module = "minuet.blink",
        async = true,
        -- Should match minuet.config.request_timeout * 1000,
        -- since minuet.config.request_timeout is in seconds
        timeout_ms = 3000,
        score_offset = 10,
      },
    }, maybe_internet_providers),
  },
  appearance = {
    kind_icons = kind_icons,
  },
  completion = {
    list = {
      -- For some reason enabled auto_insert suddenly closes the completion menu,
      -- after pressed down "select_next/select_prev" keymaps for ~1000ms.
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
