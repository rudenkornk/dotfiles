#!/usr/bin/env bash

export SOPS_EDITOR='unshare --net --map-root-user vim -Z -u DEFAULTS -i NONE -n'
# shellcheck disable=SC2139
# "This expands when defined, not when used. Consider escaping." -- intentionally left as is.
alias sops="EDITOR=\"$SOPS_EDITOR\" sops"
# shellcheck disable=SC2139
alias rvim="$SOPS_EDITOR"

alias ldaps='ldapsearch $(sops --decrypt ~/.config/ldap/ldap.auth.sops.json | jq -r '"'"'" -D " + .user + " -w " + .password + " -H " + .server + " -b " + .domain'"'"')'
