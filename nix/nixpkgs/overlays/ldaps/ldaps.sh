# shellcheck shell=bash

shopt -s nullglob

auth_file=$(sops-cached @corp_auth@)
ldap_args=$(
  jq --exit-status -r '"-D " + .email + " -w " + .password + " -H " + .ldap_server + " -b " + .ldap_domain' \
    "$auth_file"
) || {
  echo "Failed to get LDAP credentials." >&2
  exit 1
}

# shellcheck disable=SC2086
ldapsearch $ldap_args "$@"
