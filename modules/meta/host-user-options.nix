# `local.host` and `local.user` options carry host/user metadata into
# NixOS and home-manager evaluations, replacing the former `specialArgs` plumbing.
{ lib, ... }:
let
  hostOption = {
    options.local.host = lib.mkOption {
      type = lib.types.raw;
      description = "Metadata of the host this configuration is built for.";
    };
  };
  userOption = {
    options.local.user = lib.mkOption {
      type = lib.types.raw;
      description = "Metadata of the user this home configuration belongs to.";
    };
  };
in
{
  flake.modules.nixos.base = hostOption;
  flake.modules.homeManager.base.imports = [
    hostOption
    userOption
  ];
}
