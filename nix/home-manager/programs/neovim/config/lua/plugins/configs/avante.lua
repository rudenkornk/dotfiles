M = {}

-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
-- ⚠️ must add this setting! ! !
M.build = "make"

M.opts = {
  provider = os.getenv("USERKIND") == "corp" and "corp" or "copilot",
  providers = {
    corp = {
      __inherited_from = "openai",
      disable_tools = false,
      disabled_tools = { "web_search" },
      context_window = 128000,
      endpoint = os.getenv("CORP_LLM_ENDPOINT_CHAT"),
      api_key_name = "CORP_LLM_API_KEY",
      model = "Qwen3-Coder-30B-A3B-Instruct-FP8",
    },
  },
  input = {
    provider = "snacks",
    provider_opts = {
      -- Additional snacks.input options
      title = "Avante Input",
      icon = "󰇀",
    },
  },
  selector = {
    provider = "snacks",
    provider_opts = {},
  },
  mappings = {
    sidebar = {
      close_from_input = {
        normal = { "q", "<Esc>" },
        insert = "<C-d>",
      },
    },
    submit = {
      insert = "<C-g>",
    },
  },
}

return M
