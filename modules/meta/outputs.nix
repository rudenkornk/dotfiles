# Stage-1 transitional module: the entire pre-dendritic flake outputs body, moved here nearly verbatim.
# It is dissolved into feature modules over the course of the dendritic migration.
{ inputs, ... }:
let
  inherit (inputs) home-manager;
  inherit (inputs.nixpkgs) lib;
  inherit (builtins) mapAttrs;
  hm_inputs = { };
  nixos_inputs = {
    inherit (inputs)
      disko
      home-manager
      nixos-hardware
      preservation
      ;
  };
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    localSystem = system;
    config = {
      allowUnfreePredicate = import ../../nix/nixpkgs/unfree.nix { inherit lib; };
    };
    overlays = import ../../nix/nixpkgs/overlays.nix { inherit inputs; };
  };
  hostfiles = pkgs.locallib.get_modules_map ../../nix/hosts;
  hosts = mapAttrs (lib.const import) hostfiles;
  userfiles = pkgs.locallib.get_modules_map ../../nix/users;
  users = mapAttrs (lib.const import) userfiles;
  standalonePackages = pkgs.locallib.get_modules_map ../../nix/packages;

  userHostPairs = lib.cartesianProduct {
    user = lib.attrsToList users;
    host = lib.attrsToList hosts;
  };
  makeHomeConfig =
    { user, host }:
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inputs = hm_inputs;
        user = user.value;
        host = host.value;
      };
      modules = [ ../../nix/home-manager/home.nix ];
    };
  homeConfigurations = lib.listToAttrs (
    map ({ user, host }: {
      name = "${user.name}@${host.name}";
      value = makeHomeConfig { inherit user host; };
    }) userHostPairs
  );
in
{
  systems = [ system ];

  flake = {
    nixosConfigurations = mapAttrs (
      name: host:
      lib.nixosSystem {
        inherit system pkgs;
        specialArgs = {
          inputs = nixos_inputs;
          inherit hm_inputs users host;
        };
        modules = [ ../../nix/configuration.nix ];
      }
    ) hosts;

    inherit homeConfigurations;
    # Also register home-manager configs for `nix flake check`.
    checks.${system} = mapAttrs (_: config: config.activationPackage) homeConfigurations;

    packages.${system} = mapAttrs (_: path: pkgs.callPackage path { }) standalonePackages;

    devShells.${system} = import ../../nix/devshell.nix { inherit pkgs; };
  };
}
