c() {
  emulate -LR zsh
  if [[ $# -eq 0 || ( $# -eq 1 && "$1" == - ) ]]; then
    popd -q || return
  else
    local old_pwd=$PWD
    z "$@" || return
    dirstack=("$old_pwd" "${dirstack[@]}")
  fi
  eza --classify=always --icons=always --all --group-directories-first
}
compdef -e 'words[1]=z; _normal' c
