c() {
  emulate -LR zsh
  local old_pwd=$PWD
  if [[ $# -eq 0 || ( $# -eq 1 && "$1" == - ) ]]; then
    popd -q || return
    typeset -ga __c_forward
    __c_forward=("$old_pwd" "${__c_forward[@]}")
  elif [[ $# -eq 1 && "$1" == + ]]; then
    if (( ${#__c_forward[@]} == 0 )); then
      print -u2 'c: forward directory history is empty'
      return 1
    fi
    cd -- "$__c_forward[1]" || return
    dirstack=("$old_pwd" "${dirstack[@]}")
    shift __c_forward
  else
    z "$@" || return
    dirstack=("$old_pwd" "${dirstack[@]}")
    typeset -ga __c_forward=()
  fi
  eza --classify=always --icons=always --all --group-directories-first
}
compdef -e 'words[1]=z; _normal' c
