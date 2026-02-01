# Stupid `|| return 1` due to missing `set -e` support in fish functions.
# See https://github.com/fish-shell/fish-shell/issues/510

set auth_file $(@sops-cached@/bin/sops-cached  @corp_auth@) || return 1
set ldap_args $(\
  @jq@/bin/jq --exit-status -r '"-D " + .email + " -w " + .password + " -H " + .ldap_server + " -b " + .ldap_domain' \
  $auth_file | string split " "\
) || { echo "Failed to get LDAP credentials." >&2; return 1 }

@openldap@/bin/ldapsearch $ldap_args $argv
