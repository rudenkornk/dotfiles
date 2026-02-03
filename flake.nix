{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-25.11";
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
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tmux_plugin_ukiyo = {
      url = "github:nybkox/tmux-ukiyo";
      flake = false;
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
      hosts = mapAttrs (name: file: { inherit name file; }) hostfiles;
      userfiles = pkgs.locallib.get_modules_map ./nix/users;
      users = mapAttrs (lib.const import) userfiles;
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

      homeConfigurations = mapAttrs (
        name: user:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs user; };
          modules = [ ./nix/home-manager/home.nix ];
        }
      ) users;
      # Also register home-manager configs for `nix flake check`.
      checks."${system}" = mapAttrs (name: config: config.activationPackage) homeConfigurations;

      devShells.${system}.default = import ./nix/devshell.nix { inherit pkgs; };
    };
}
