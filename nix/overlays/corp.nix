_: final: prev: {
  corp = {
    ldaps = final.writeShellApplication {
      name = "ldaps";
      runtimeInputs = [
        final.jq
        final.openldap
        final.custom.sops-cached
      ];
      text =
        final.lib.replaceStrings [ "@corp_auth@" ] [ "${final.locallib.secrets + /corp/auth.sops.json}" ]
          (builtins.readFile ./corp/ldaps.sh);
    };

    openconnect-run = final.writeShellApplication {
      name = "openconnect-corp-run";
      runtimeInputs = [
        final.jq
        final.openconnect
        final.custom.sops-cached
      ];
      text =
        final.lib.replaceStrings [ "@corp_auth@" ] [ "${final.locallib.secrets + /corp/auth.sops.json}" ]
          (builtins.readFile ./corp/openconnect-run.sh);
    };

    openvpn-run = final.writeShellApplication {
      name = "openvpn-corp-run";
      runtimeInputs = [
        final.openvpn
        final.gnused
        final.socat
        final.uutils-coreutils-noprefix
        final.tmux
        final.custom.sops-cached
      ];
      text =
        final.lib.replaceStrings
          [ "@corp_pins@" "@openvpn_config@" ]
          [
            "${final.locallib.secrets + /corp/pins.txt.sops}"
            "${final.locallib.secrets + /corp/openvpn.conf.sops}"
          ]
          (builtins.readFile ./corp/openvpn-run.sh);
    };

    pkgs-info = builtins.fromJSON (
      builtins.readFile (final.locallib.secrets + /corp/packages_info.sops.json)
    );
  };
}
