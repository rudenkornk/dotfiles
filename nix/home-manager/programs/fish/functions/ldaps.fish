set ldap_args $(\
  @jq@/bin/jq -r '" -D " + .user + " -w " + .password + " -H " + .server + " -b " + .domain' \
  $(@sops-cached@/bin/sops-cached  @ldap_auth@) |\
  string split " "\
)
ldapsearch $ldap_args $argv
