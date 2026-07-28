# git, wrapped with the global config baked in (GIT_CONFIG_GLOBAL).
# The exported `packages.git` is identity-free; each user's home installs a
# re-wrapped variant with the `[user]` section from `flake.meta`.
{ config, ... }:
let
  flakeCfg = config;
in
{
  flake = {
    wrappers.git = { wlib, pkgs, ... }: {
      imports = [ wlib.wrapperModules.git ];
      package = pkgs.git;
      # The `[include] path = user.ini` line in this file silently no-ops in
      # the baked config (git skips missing includes); identity comes from
      # the per-user re-wrap below instead.
      configFile.content = builtins.readFile ./_configs/.config/git/config;
    };

    wrappers.fish.shellAliases = {
      g = "git";
      a = "arc";
    };

    modules.homeManager.base = { config, pkgs, ... }: {
      home = {
        packages = with pkgs; [
          (flakeCfg.flake.wrappers.git.wrap {
            inherit pkgs;
            settings.user = { inherit (config.local.user) name email; };
          })
          git-lfs
          gh
        ];
        shellAliases = {
          g = "git";
          a = "arc";
        };

        # Links the arc config; the linked git config is superseded by the
        # baked GIT_CONFIG_GLOBAL and kept only as a plain-file reference.
        file = pkgs.locallib.homefiles {
          inherit (config) xdg;
          path = ./_configs;
        };
      };
    };
  };
}
