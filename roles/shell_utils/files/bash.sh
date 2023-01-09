#!/usr/bin/env bash

function c() {
  cd "$@" && ls -a;
}
alias b="bat --paging=never"
alias l="exa --classify"
alias ll="exa --long --classify --icons --octal-permissions"
alias la="exa --classify --all"
