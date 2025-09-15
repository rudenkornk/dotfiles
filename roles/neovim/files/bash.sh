#!/usr/bin/env bash

export VISUAL=nvim
export EDITOR="$VISUAL"

alias v=nvim
alias vi=nvim
alias vd="nvim -d"

# See neovim.fish for explanation.
if [[ -n "$NVIM" && -n "$MYVIMRC" ]]; then
  unset HTTP_PROXY
  unset HTTPS_PROXY
  unset TAVILY_API_KEY
  unset MORPH_API_KEY
  unset CORP_LLM_API_KEY
fi
