# shellcheck shell=bash

c() {
  if [[ $# -eq 0 || ($# -eq 1 && "$1" == -) ]]; then
    popd >/dev/null || return
  else
    local old_pwd=$PWD
    z "$@" || return
    pushd -n "$old_pwd" >/dev/null || return
  fi
  eza --classify=always --icons=always --all --group-directories-first
}
