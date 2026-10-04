unalias g
function g() {
  if [[ "$PWD" =~ '/(arcadia|cloudia)' ]]; then
    arc "$@"
  else
    git "$@"
  fi
}
compdef -e 'words[1]=git; _normal' g
