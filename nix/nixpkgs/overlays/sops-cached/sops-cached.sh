# shellcheck shell=bash

file="$1"
suffix="${2:-}"

decrypted_name=$(basename "$file")_$(sha1sum "$file" | head -c 10)_decrypted
decrypted=/run/user/"$(id --user)"/secrets/"$decrypted_name"
if [[ -n "$suffix" ]]; then
  # Suffix allows making a specific name for a secret.
  # For example some programs may require fixed names for their configs.
  decrypted="${decrypted}/${suffix}"
fi

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
