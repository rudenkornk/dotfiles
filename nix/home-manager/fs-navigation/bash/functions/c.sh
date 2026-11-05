# shellcheck shell=bash

c() {
  local old_pwd=$PWD
  if [[ $# -eq 0 || ($# -eq 1 && "$1" == -) ]]; then
    popd >/dev/null || return
    __c_forward+=("$old_pwd")
  elif [[ $# -eq 1 && "$1" == + ]]; then
    if [[ ${#__c_forward[@]} -eq 0 ]]; then
      printf 'c: forward directory history is empty\n' >&2
      return 1
    fi
    local target=${__c_forward[-1]}
    cd -- "$target" || return
    pushd -n "$old_pwd" >/dev/null || return
    unset '__c_forward[-1]'
  else
    z "$@" || return
    pushd -n "$old_pwd" >/dev/null || return
    __c_forward=()
  fi
  eza --classify=always --icons=always --all --group-directories-first
}
