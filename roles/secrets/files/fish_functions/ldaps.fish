function ldaps --wraps ldapsearch
    set ldap_user $(cat ~/.config/ldap/ldap_user.auth)
    set ldap_server $(cat ~/.config/ldap/ldap_server.auth)
    set ldap_domain $(cat ~/.config/ldap/ldap_domain.auth)
    set ldap_pass ~/.config/ldap/ldap_pass.auth
    ldapsearch -H "$ldap_server" -D "$ldap_user" -y "$ldap_pass" -b "$ldap_domain" $argv
end
