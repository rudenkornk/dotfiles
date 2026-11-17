_: final: prev: {
  corp = {
    arc-delta = final.writeShellApplication {
      name = "arc-delta";
      runtimeInputs = [ final.delta ];
      text = builtins.readFile ./corp/arc-delta.sh;
    };

    ca-bundle = final.concatText "corp-ca-bundle.pem" [
      (final.locallib.secrets + /corp/YandexInternalRootCA.crt)
      (final.locallib.secrets + /corp/YCKZInternalRootCA.crt)
      (final.locallib.secrets + /corp/YandexInternalCA.crt)
    ];

    cacert = final.cacert.override { extraCertificateFiles = [ final.corp.ca-bundle ]; };

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

    pkgs-info =
      let
        override = builtins.getEnv "DOTFILES_PACKAGES_INFO_FILE";
      in
      builtins.fromJSON (
        if override != "" then
          builtins.readFile override
        else
          builtins.readFile (final.locallib.secrets + /corp/packages_info.sops.json)
      );
  };
}
