# `local.host` (and later `local.user`) options carry host/user metadata into
# NixOS and home-manager evaluations, replacing the former `specialArgs` plumbing.
{ lib, ... }:
let
  hostOption = {
    options.local.host = lib.mkOption {
      type = lib.types.raw;
      description = "Metadata of the host this configuration is built for.";
    };
  };
in
{
  flake.modules.nixos.base = hostOption;
}
