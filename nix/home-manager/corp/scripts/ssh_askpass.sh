# shellcheck shell=bash

set +x
config=$(sops-cached @skotty_config@)
if ! pin=$(yq -er '.keyring.yubikey.pin | select(tag == "!!str") |
  select(test("^plain:[a-zA-Z0-9]{6,8}$"))' "$config" 2>/dev/null); then
  echo "Expected a plain YubiKey PIN in the encrypted Skotty configuration." >&2
  exit 1
fi

printf '%s\n' "${pin#plain:}"
