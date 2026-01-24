# shellcheck shell=bash

file="$1"

decrypted=/run/user/"$(id --user)"/secrets/$(basename "$file")_decrypted
if [[ -f "$decrypted" ]]; then
  echo "$decrypted"
  exit
fi
mkdir --parents "$(dirname "$decrypted")"
touch "$decrypted" && chmod 600 "$decrypted"
if sops --decrypt "$file" >"$decrypted"; then
  echo "$file is decrypted and cached." >&2
else
  echo "$file is failed to decrypt, no more attempts will be made." >&2
fi
echo "$decrypted"
