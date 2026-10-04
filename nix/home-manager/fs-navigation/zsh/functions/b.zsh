b() {
  if [[ $# -gt 0 && -f "$1" && $(file --brief --mime-type -- "$1") == image/* ]]; then
    kitten icat --fit both -- "$@"
  else
    bat "$@"
  fi
}
compdef -e 'words[1]=bat; _normal' b
