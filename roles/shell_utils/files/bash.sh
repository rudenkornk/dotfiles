#!/usr/bin/env bash

alias b="bat --paging=never"
alias l="eza --classify --icons"
alias ls="eza --classify --icons"
alias ll="eza --classify --icons --long --octal-permissions"
alias la="eza --classify --icons --all"

eval "$(zoxide init bash)"

source ~/.local/bin/yazi_dir/completions/ya.bash
source ~/.local/bin/yazi_dir/completions/yazi.bash

function c() {
  pushd "$@" && eza --classify --icons

  if [[ "$argv" == "-" ]] || [[ -z "$argv" ]]; then
    popd && eza --classify --icons
  else
    pushd .
    __zoxide_z "$argv" && exa --classify --icons
  fi
}

# See https://yazi-rs.github.io/docs/quick-start#shell-wrapper
function yy() {
  local tmp
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    pushd "$cwd" && exa --classify --icons
  fi
  rm -f -- "$tmp"
}
