# shellcheck shell=bash
# See neovim.fish for explanation.
# Keep this unset list in sync with neovim.fish.
if [[ -n "$NVIM" && -n "$MYVIMRC" ]]; then
  unset HTTP_PROXY
  unset HTTPS_PROXY
  unset http_proxy
  unset https_proxy

  unset ANTHROPIC_API_KEY
  unset CODESTRAL_API_KEY
  unset DEEPSEEK_API_KEY
  unset GEMINI_API_KEY
  unset GITHUB_API_KEY
  unset MORPH_API_KEY
  unset OPENAI_API_KEY
  unset OPENAI_BASE_URL
  unset OPENAI_MODEL
  unset OPENROUTER_API_KEY
  unset TAVILY_API_KEY

  unset CORP_LLM_API_KEY
  unset CORP_LLM_ENDPOINT_COMPLETIONS
fi
