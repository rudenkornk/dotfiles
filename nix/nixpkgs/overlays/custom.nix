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
