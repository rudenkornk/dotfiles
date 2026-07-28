# opencode, wrapped with runtime secret env and a baked global config.
# The corp userkind instead reads its config and auth from runtime-decrypted
# files in the standard XDG locations.
{ config, ... }:
let
  flakeCfg = config;
  ailib = import ./_lib.nix;
in
{
  flake = {
    wrappers.opencode = { lib, ... }: {
      imports = [ (ailib.mkSecretTool { package = pkgs: pkgs.unstable.opencode; }) ];
      runShell = [
        {
          name = "opencode-config";
          after = [ "secret-env" ];
          data = ''
            if [ "''${USERKIND:-}" != "corp" ] && [ -z "''${OPENCODE_CONFIG:-}" ]; then
              export OPENCODE_CONFIG=${./opencode.jsonc}
            fi
          '';
        }
      ];
    };

    modules.homeManager.base =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        home.packages = [ flakeCfg.flake.packages.${pkgs.stdenv.hostPlatform.system}.opencode ];

        xdg.dataFile = {
          # W/A for https://github.com/anomalyco/opencode/issues/16885
          "opencode/opencode.db".source =
            config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/opencode/opencode-stable.db";
        };

        local = {
          secrets.links =
            { }
            // lib.optionalAttrs (config.local.user.userkind == "corp") {
              "${config.xdg.dataHome}/opencode/auth.json".source =
                pkgs.locallib.secrets + /corp/opencode.auth.json.sops;
              "${config.xdg.configHome}/opencode/opencode.jsonc".source =
                pkgs.locallib.secrets + /corp/opencode.jsonc.sops;
            };
        };
      };
  };
}
