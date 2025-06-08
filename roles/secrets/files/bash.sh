#!/usr/bin/env bash

export SOPS_EDITOR='unshare --net --map-root-user vim -Z -u DEFAULTS -i NONE -n'
alias sops="EDITOR=\"$SOPS_EDITOR\" sops"
alias rvim="$SOPS_EDITOR"

alias ldaps='ldapsearch $(sops --decrypt ~/.config/ldap/ldap.auth.sops.json | jq -r '"'"'" -D " + .user + " -w " + .password + " -H " + .server + " -b " + .domain'"'"')'
