# See ../fish/conf.d/neovim.fish for explanation.
# Keep this unset list in sync with ../bash/init_extra.sh, also used by zsh.
if ($env.NVIM? | default '' | is-not-empty) and ($env.MYVIMRC? | default '' | is-not-empty) {
  hide-env --ignore-errors PROXY_APP HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
  hide-env --ignore-errors ANTHROPIC_API_KEY CODESTRAL_API_KEY DEEPSEEK_API_KEY GEMINI_API_KEY
  hide-env --ignore-errors GITHUB_API_KEY MORPH_API_KEY OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL
  hide-env --ignore-errors OPENROUTER_API_KEY TAVILY_API_KEY CORP_LLM_API_KEY CORP_LLM_ENDPOINT_COMPLETIONS
}
