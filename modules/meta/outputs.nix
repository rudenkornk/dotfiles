# Transitional module: standalone home-manager configurations, packages and
# dev shells still built from the pre-dendritic `nix/` tree.
# It is dissolved into feature modules over the course of the dendritic migration.
{
  config,
  inputs,
  withSystem,
  ...
}:
let
  inherit (inputs.nixpkgs) lib;
  inherit (builtins) mapAttrs;

  userHostPairs = lib.cartesianProduct {
    user = lib.attrNames config.flake.meta.users;
    host = lib.attrNames config.flake.meta.hosts;
  };
  makeHomeConfig =
    { user, host }:
    withSystem "x86_64-linux" (
      { pkgs, ... }:
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inputs = { };
          user = config.flake.meta.users.${user};
          host = config.flake.meta.hosts.${host};
        };
        modules = [ ../../nix/home-manager/home.nix ];
      }
    );
  homeConfigurations = lib.listToAttrs (
    map ({ user, host }: {
      name = "${user}@${host}";
      value = makeHomeConfig { inherit user host; };
    }) userHostPairs
  );
in
{
  flake = {
    inherit homeConfigurations;
    # Also register home-manager configs for `nix flake check`.
    checks."x86_64-linux" = mapAttrs (_: cfg: cfg.activationPackage) homeConfigurations;

    packages."x86_64-linux" = withSystem "x86_64-linux" (
      { pkgs, ... }:
      mapAttrs (_: path: pkgs.callPackage path { }) (pkgs.locallib.get_modules_map ../../nix/packages)
    );

    devShells."x86_64-linux" = withSystem "x86_64-linux" (
      { pkgs, ... }: import ../../nix/devshell.nix { inherit pkgs; }
    );
  };
}
