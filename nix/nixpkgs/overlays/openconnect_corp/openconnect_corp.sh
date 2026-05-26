# shellcheck shell=bash

shopt -s nullglob

auth_file=$(sops-cached @corp_auth@)
openconnect_args=$(
  jq --exit-status -r '"--server " + .vpn_server + " --user " + .user' "$auth_file"
) || {
  echo "Failed to get OpenConnect credentials." >&2
  exit 1
}
password=$(
  jq --exit-status -r '.password' "$auth_file"
) || {
  echo "Failed to get password." >&2
  exit 1
}

# shellcheck disable=SC2086
echo "$password" | sudo openconnect $openconnect_args "$@"
