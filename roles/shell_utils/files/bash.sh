#!/usr/bin/env bash

function c() {
  cd "$@" && eza --classify --icons;
}
alias b="bat --paging=never"
alias l="eza --classify --icons"
alias ls="eza --classify --icons"
alias ll="eza --classify --icons --long --octal-permissions"
alias la="eza --classify --icons --all"

eval "$(zoxide init bash)"
