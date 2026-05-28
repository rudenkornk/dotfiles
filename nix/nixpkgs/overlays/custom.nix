_: final: _: {
  custom = {
    sops-cached =
      # Simple wrapper over sops, which cache its output in tmpfs /run/user/$id/ dir.
      # This is primarily needed to avoid multiple costly decryption queries when using TPM.
      final.writeShellApplication {
        name = "sops-cached";
        runtimeInputs = [
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
        final.lib.replaceStrings [ "@corp_auth@" ] [ "${final.locallib.secrets + /corp_auth.sops.json}" ]
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
        final.lib.replaceStrings [ "@corp_auth@" ] [ "${final.locallib.secrets + /corp_auth.sops.json}" ]
          (builtins.readFile ./custom/openconnect_corp.sh);
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

    vim-spell =
      let
        base = "https://ftp.nluug.nl/vim/runtime/spell";
        fetch =
          name: hash:
          final.fetchurl {
            url = "${base}/${name}";
            inherit hash;
          };
      in
      final.stdenv.mkDerivation {
        name = "vim-spell";
        srcs = [
          (fetch "en.utf-8.spl" "sha256-/sq9yUm2o50ywImfolReqyXmPy7QozxK0VEUJjhNMHA=")
          (fetch "en.utf-8.sug" "sha256-W25eYWVYLS/Xob+kH7zoJCxyR2IixV0XwqorqTPJMuw=")
          (fetch "ru.utf-8.spl" "sha256-6y0714ogILMLzAp8/r2s6/t6QnWBEU9muIpXeubaxU0=")
          (fetch "ru.utf-8.sug" "sha256-6r2GForYXVv7gGiAjPeYK6sDdK/CmctJ7MidcWFvOTs=")
          (fetch "de.utf-8.spl" "sha256-c8cQfqM5hWzb6SHeuSpFk5xN5uucByYdobndGfaDo9E=")
          (fetch "de.utf-8.sug" "sha256-E9Ds+Shj2J72DNSopesqWhOg6Pm6jRxqvkerqFcUqUg=")
          (fetch "fr.utf-8.spl" "sha256-q/uXArmNiHwXWs5Y8as5cz3AjQO2dNkU9WNE74bmO2E=")
          (fetch "fr.utf-8.sug" "sha256-ApS8MrQskLuyhqieI8o3c7fvUO/xq1I7FRPWolxrP1g=")
          (fetch "la.utf-8.spl" "sha256-MQr0CpSQWbqcnm+Po3UgGV8Zs5/CKTN+pvHcf7+ivqc=")
          (fetch "es.utf-8.spl" "sha256-ljY3rJJc+KUb8gf6w5LWtMaXlXEdzC1ICbeIRq42e+M=")
          (fetch "es.utf-8.sug" "sha256-5w80eKplPCrpBQhjKPv/TkO9ZG12U0ZF9QplNEgBvWw=")
          (fetch "it.utf-8.spl" "sha256-2AczkD6DbVN5DAq4wcLyn2Y8oqd67ns4Guprh2KudBM=")
          (fetch "it.utf-8.sug" "sha256-4LsXYaeScJJrdaj69PTQ2EDVWis0UY/Y5RKSfCckzko=")
          (fetch "pl.utf-8.spl" "sha256-FM5QZEzT9p1adhtptZOKbQMYIytctqgB3DTCPaWF5+k=")
        ];
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out/spell
          for f in $srcs; do
            cp "$f" "$out/spell/$(stripHash "$f")"
          done
        '';
      };
  };
}
