# shellcheck shell=bash

unalias g 2>/dev/null || true
g() {
  if [[ "$PWD" =~ /(arcadia|cloudia) ]]; then
    arc "$@"
  else
    git "$@"
  fi
}
