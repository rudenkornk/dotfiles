_: final: _: {
  ldaps = final.writeShellApplication {
    name = "ldaps";
    runtimeInputs = [
      final.jq
      final.openldap
      final.sops-cached
    ];
    text =
      final.lib.replaceStrings [ "@corp_auth@" ] [ "${final.locallib.secrets + /corp_auth.sops.json}" ]
        (builtins.readFile ./ldaps/ldaps.sh);
  };
}
