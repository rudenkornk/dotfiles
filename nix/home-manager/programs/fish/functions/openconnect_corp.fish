# Stupid `|| return 1` due to missing `set -e` support in fish functions.
# See https://github.com/fish-shell/fish-shell/issues/510

set auth_file $(@sops-cached@/bin/sops-cached  @corp_auth@) || return 1
set openconnect_args $(\
  @jq@/bin/jq --exit-status -r '"--server " + .vpn_server + " --user " + .user' $auth_file |\
  string split " "\
) || { echo "Failed to get OpenConnect credentials." >&2; return 1 }
set -l password (@jq@/bin/jq --exit-status -r '.password' $auth_file) || { echo "Failed to get password." >&2; return 1 }

echo $password | sudo @openconnect@/bin/openconnect $openconnect_args $argv
