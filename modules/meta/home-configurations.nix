# Standalone home-manager configurations: the cartesian product of all users
# and hosts, each registered as a flake check as well.
{
  config,
  inputs,
  withSystem,
  ...
}:
let
  inherit (inputs.nixpkgs) lib;
  flakeCfg = config;

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
        modules = [
          flakeCfg.flake.modules.homeManager."user-${user}"
          { local.host = flakeCfg.flake.meta.hosts.${host}; }
        ];
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
    checks."x86_64-linux" = builtins.mapAttrs (_: cfg: cfg.activationPackage) homeConfigurations;
  };
}
