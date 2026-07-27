# Embed a home-manager configuration for every user into each NixOS system.
{ config, inputs, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.base = { config, pkgs, ... }: {
    imports = [ inputs.home-manager.nixosModules.default ];

    home-manager = {
      useGlobalPkgs = true;
      sharedModules = [ { local.host = config.local.host; } ];
      users = builtins.mapAttrs (name: _: {
        imports = [ flakeCfg.flake.modules.homeManager."user-${name}" ];
      }) flakeCfg.flake.meta.users;
      backupCommand = "${pkgs.lib.getExe pkgs.trash-cli}";
    };
  };
}
