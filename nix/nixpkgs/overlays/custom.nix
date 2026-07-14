_: final: prev: {
  custom = {
    sops-cached =
      # Simple wrapper over sops, which cache its output in tmpfs /run/user/$id/ dir.
      # This is primarily needed to avoid multiple costly decryption queries when using TPM.
      final.writeShellApplication {
        name = "sops-cached";
        runtimeInputs = [
          final.age
          final.age-plugin-tpm
          final.sops
          final.uutils-coreutils-noprefix
        ];
        text = builtins.readFile ./custom/sops-cached.sh;
      };

    ldaps = final.writeShellApplication {
      name = "ldaps";
      runtimeInputs = [
        final.jq
        final.openldap
        final.custom.sops-cached
      ];
      text =
        final.lib.replaceStrings [ "@corp_auth@" ] [ "${final.locallib.secrets + /corp/auth.sops.json}" ]
          (builtins.readFile ./custom/ldaps.sh);
    };

    openconnect_corp = final.writeShellApplication {
      name = "openconnect_corp";
      runtimeInputs = [
        final.jq
        final.openconnect
        final.custom.sops-cached
      ];
      text =
        final.lib.replaceStrings [ "@corp_auth@" ] [ "${final.locallib.secrets + /corp/auth.sops.json}" ]
          (builtins.readFile ./custom/openconnect_corp.sh);
    };

    corp-pkgs-info = builtins.fromJSON (
      builtins.readFile (final.locallib.secrets + /corp/packages_info.sops.json)
    );

    throne-run = final.writeShellApplication {
      name = "throne-run";
      runtimeInputs = [ final.throne ];
      text = builtins.readFile ./custom/throne-run.sh;
    };

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
          (builtins.readFile ./custom/sing-box-run.sh);
    };

    playwright-cli = import ./custom/playwright-cli.nix final prev;

    vim-spell = import ./custom/vim-spell.nix final prev;
  };
}
