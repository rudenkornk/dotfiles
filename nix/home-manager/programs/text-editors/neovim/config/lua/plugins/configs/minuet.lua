local M = {}

M.opts = {
  provider = os.getenv("USERKIND") == "corp" and "openai_fim_compatible" or nil,
  n_completions = 1,
  provider_options = {
    openai_fim_compatible = {
      end_point = os.getenv("CORP_LLM_ENDPOINT_COMPLETIONS"),
      api_key = "CORP_LLM_API_KEY",
      model = "Qwen2.5-Coder-7B-Instruct-fp8",
      name = "qwen",
      optional = {
        max_tokens = 2000,
      },
      template = {
        prompt = function(context_before_cursor, context_after_cursor, opts)
          return "<|fim_prefix|>"
            .. context_before_cursor
            .. "<|fim_suffix|>"
            .. context_after_cursor
            .. "<|fim_middle|>"
        end,
        suffix = false,
      },
    },
  },
}

return M
