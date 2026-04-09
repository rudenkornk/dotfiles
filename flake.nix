{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-25.11";
    };
    nixpkgs_unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    nur = {
      url = "github:nix-community/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      inherit (inputs) home-manager;
      inherit (inputs.nixpkgs) lib;
      inherit (builtins) mapAttrs;
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfreePredicate = import ./nix/nixpkgs/unfree.nix { inherit lib; };
        };
        overlays = import ./nix/nixpkgs/overlays.nix { inherit inputs; };
      };
      hostfiles = pkgs.locallib.get_modules_map ./nix/hosts;
      hosts = mapAttrs (name: file: import file // { inherit name; }) hostfiles;
      userfiles = pkgs.locallib.get_modules_map ./nix/users;
      users = mapAttrs (lib.const import) userfiles;

      userHostPairs = lib.cartesianProduct {
        user = lib.attrsToList users;
        host = lib.attrsToList hosts;
      };
      makeHomeConfig =
        { user, host }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
            user = user.value;
            host = host.value;
          };
          modules = [ ./nix/home-manager/home.nix ];
        };
    in
    rec {
      nixosConfigurations = mapAttrs (
        name: host:
        lib.nixosSystem {
          inherit system pkgs;
          specialArgs = { inherit inputs users host; };
          modules = [ ./nix/configuration.nix ];
        }
      ) hosts;

      homeConfigurations = lib.listToAttrs (
        map (
          { user, host }:
          {
            name = "${user.name}@${host.name}";
            value = makeHomeConfig { inherit user host; };
          }
        ) userHostPairs
      );
      # Also register home-manager configs for `nix flake check`.
      checks."${system}" = mapAttrs (_: config: config.activationPackage) homeConfigurations;

      devShells.${system}.default = import ./nix/devshell.nix { inherit pkgs; };
    };
}
