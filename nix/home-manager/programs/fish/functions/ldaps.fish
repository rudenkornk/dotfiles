set ldap_args $(\
  sops --decrypt @ldap_auth@ |\
  jq -r '" -D " + .user + " -w " + .password + " -H " + .server + " -b " + .domain' |\
  string split " "\
)
ldapsearch $ldap_args $argv
