#!/usr/bin/env bash

stty erase '^?'
stty -ixon

alias v=nvim
alias vd="nvim -d"

# See neovim.fish for explanation.
if [[ -n "$NVIM" && -n "$MYVIMRC" ]]; then
  unset HTTP_PROXY
  unset HTTPS_PROXY
  unset http_proxy
  unset https_proxy

  unset OPENAI_API_KEY
  unset OPENAI_BASE_URL
  unset OPENAI_MODEL
  unset GEMINI_API_KEY
  unset CODESTRAL_API_KEY
  unset DEEPSEEK_API_KEY
  unset TAVILY_API_KEY
  unset MORPH_API_KEY

  unset CORP_LLM_API_KEY
  unset CORP_LLM_ENDPOINT_COMPLETIONS
fi
