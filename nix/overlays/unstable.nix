{ inputs, ... }:
final: prev:

let
  overlay_modules = import ./locallib/get_modules.nix null ./unstable;
  overlays = map import overlay_modules;
in
{
  unstable = import inputs.nixpkgs-unstable {
    localSystem = prev.stdenv.hostPlatform.system;
    inherit (prev) config;
    inherit overlays;
  };
}
