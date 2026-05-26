_: final: _: {
  sing-box-run = final.writeShellApplication {
    name = "sing-box-run";
    runtimeInputs = [
      final.bash
      final.sing-box
      final.sops
    ];
    text =
      final.lib.replaceStrings
        [ "@default_config@" ]
        [ "${final.locallib.secrets + /vpn/beta.json.sops}" ]
        (builtins.readFile ./sing-box-run/sing-box-run.sh);
  };
}
