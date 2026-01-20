set ldap_args $(\
  @jq@/bin/jq -r '" -D " + .email + " -w " + .password + " -H " + .ldap_server + " -b " + .ldap_domain' \
  $(@sops-cached@/bin/sops-cached  @corp_auth@) |\
  string split " "\
)
ldapsearch $ldap_args $argv
