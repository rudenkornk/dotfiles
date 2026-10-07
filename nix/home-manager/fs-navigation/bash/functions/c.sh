# shellcheck shell=bash

c() {
  if [[ $# -eq 0 || ($# -eq 1 && "$1" == -) ]]; then
    popd >/dev/null || return
  else
    pushd . >/dev/null || return
    z "$@" || return
  fi
  eza --classify=always --icons=always --all --group-directories-first
}
