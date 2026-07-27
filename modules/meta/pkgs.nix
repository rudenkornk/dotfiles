# The single shared nixpkgs instance used by every configuration:
# NixOS systems, home-manager configurations, packages, and dev shells.
# Everything obtains it via `withSystem` or the `pkgs` argument of `perSystem`.
{ inputs, ... }: {
  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      localSystem = system;
      config = {
        allowUnfreePredicate = import ../../nix/nixpkgs/unfree.nix { inherit (inputs.nixpkgs) lib; };
      };
      overlays = import ../../nix/nixpkgs/overlays.nix { inherit inputs; };
    };
  };
}
