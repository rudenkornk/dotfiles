# shellcheck shell=bash

b() {
  if [[ $# -gt 0 && -f "$1" && $(file --brief --mime-type -- "$1") == image/* ]]; then
    kitten icat --fit both -- "$@"
  else
    bat "$@"
  fi
}
