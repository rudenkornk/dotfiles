#!/usr/bin/env bash

export SOPS_EDITOR='unshare --net --map-root-user vim -Z -u DEFAULTS -i NONE -n'
alias sops="EDITOR=\"$SOPS_EDITOR\" sops"
alias rvim="$SOPS_EDITOR"

ldap_user='$(cat ~/.config/ldap/ldap_user.auth)'
ldap_server='$(cat ~/.config/ldap/ldap_server.auth)'
ldap_domain='$(cat ~/.config/ldap/ldap_domain.auth)'
ldap_pass=~/.config/ldap/ldap_pass.auth

alias ldaps="ldapsearch -H \"$ldap_server\" -D \"$ldap_user\" -y \"$ldap_pass\" -b \"$ldap_domain\""
