_: final: _: {
  openconnect_corp = final.writeShellApplication {
    name = "openconnect_corp";
    runtimeInputs = [
      final.jq
      final.openconnect
      final.sops-cached
    ];
    text =
      final.lib.replaceStrings [ "@corp_auth@" ] [ "${final.locallib.secrets + /corp_auth.sops.json}" ]
        (builtins.readFile ./openconnect_corp/openconnect_corp.sh);
  };
}
