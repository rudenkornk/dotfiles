# Embed a home-manager configuration for every user into each NixOS system.
{ config, inputs, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.base = { config, pkgs, ... }: {
    imports = [ inputs.home-manager.nixosModules.default ];

    home-manager = {
      extraSpecialArgs = {
        inputs = { };
        inherit pkgs;
        host = config.local.host;
      };
      users = builtins.mapAttrs (name: user: {
        # `home-manager.extraSpecialArgs` is shared across all users,
        # so there is no built-in way to inject per-user data that way.
        # To work around this, we re-export `user` through `_module.args` here,
        # which makes it available as a regular module argument in home-manager modules.
        _module.args.user = user;
        imports = [ ../../nix/home-manager/home.nix ];
      }) flakeCfg.flake.meta.users;
      backupCommand = "${pkgs.lib.getExe pkgs.trash-cli}";
    };
  };
}
