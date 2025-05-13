#!/usr/bin/env bash

ldap_user='$(cat ~/.config/ldap/ldap_user.auth)'
ldap_server='$(cat ~/.config/ldap/ldap_server.auth)'
ldap_domain='$(cat ~/.config/ldap/ldap_domain.auth)'
ldap_pass=~/.config/ldap/ldap_pass.auth

alias ldaps="ldapsearch -H \"$ldap_server\" -D \"$ldap_user\" -y \"$ldap_pass\" -b \"$ldap_domain\""
