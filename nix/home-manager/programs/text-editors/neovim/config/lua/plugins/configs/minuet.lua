local M = {}

M.opts = {
  provider = "openai_fim_compatible",
  n_completions = 2,
  context_window = 8192,
  request_timeout = 3,
  throttle = 1500, -- Time to send a new request after the last request was sent.
  debounce = 300, -- Time to send a request after the last keystroke was hit.
  virtualtext = {
    auto_trigger_ft = { "*" },
  },

  provider_options = {
    openai_fim_compatible = {
      api_key = "DEEPSEEK_API_KEY",
      name = "Deepseek",
      optional = {
        max_tokens = 512,
        top_p = 0.9,
      },
    },
  },
}

return M
