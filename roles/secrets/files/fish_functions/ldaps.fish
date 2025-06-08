function ldaps --wraps ldapsearch
    set ldap_args $(\
        sops --decrypt ~/.config/ldap/ldap.auth.sops.json |\
        jq -r '" -D " + .user + " -w " + .password + " -H " + .server + " -b " + .domain' |\
        string split " "\
    )
    ldapsearch $ldap_args $argv
end
