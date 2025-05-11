#!/usr/bin/env bash

alias b="bat --paging=never"
alias l="eza --classify --icons"
alias ls="eza --classify --icons"
alias ll="eza --classify --icons --long --octal-permissions"
alias la="eza --classify --icons --all"

eval "$(zoxide init bash)"

source ~/.local/yazi/completions/ya.bash
source ~/.local/yazi/completions/yazi.bash
export PATH="$HOME/.local/yazi:$PATH"

function c() {
  pushd "$@" && eza --classify --icons

  if [[ "$argv" == "-" ]] || [[ -z "$argv" ]]; then
    popd && eza --classify --icons
  else
    pushd .
    z "$argv" && eza --classify --icons
  fi
}

# See https://yazi-rs.github.io/docs/quick-start#shell-wrapper
function yy() {
  local tmp
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    pushd "$cwd" && eza --classify --icons
  fi
  rm -f -- "$tmp"
}
