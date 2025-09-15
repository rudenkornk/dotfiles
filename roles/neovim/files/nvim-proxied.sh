#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

secrets=(
  "$HOME/.config/dotfiles-secrets/proxy.sh.sops"
  "$HOME/.config/dotfiles-secrets/keys.sh.sops"
)
tmp_dir="$HOME/.local/tmp"

# TODO: make this transient with some sort of tmpfs.
# Decrypting these every time is slow.
for secret in "${secrets[@]}"; do
  tmp_file="$tmp_dir/$(basename "${secret%.sops}")"
  if [[ ! -f $tmp_file ]]; then
    mkdir -p "$(dirname "$tmp_file")"
    touch "$tmp_file" && chmod 600 "$tmp_file"
    sops --decrypt "$secret" >"$tmp_file" || true
  fi

  if [[ -f $tmp_file ]]; then
    # shellcheck source=/dev/null
    source "$tmp_file"
  fi
done

~/.local/nvim-linux-"$(uname --machine)"/bin/nvim "$@"
