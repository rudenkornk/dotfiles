{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-25.11";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    tmux_plugin_kanagawa = {
      url = "github:rudenkornk/tmux-kanagawa";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      inherit (inputs) home-manager;
      inherit (inputs.nixpkgs) lib;
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfreePredicate = import ./nix/unfree.nix { inherit lib; };
        };
        overlays = import ./nix/nixpkgs/overlays.nix { inherit inputs; };
      };
      hostfiles = pkgs.locallib.get_modules ./nix/hosts;
      hosts = lib.mapAttrs (name: file: { inherit name file; }) hostfiles;
      users = {
        rudenkornk = {
          username = "rudenkornk";
          description = "Nikita Rudenko";
          userkind = "default";
        };
        rudenkornk_corp = {
          username = "rudenkornk_corp";
          description = "Nikita Rudenko (corp)";
          userkind = "corp";
        };
      };
    in
    rec {
      nixosConfigurations = builtins.mapAttrs (
        name: host:
        lib.nixosSystem {
          inherit system pkgs;
          specialArgs = { inherit inputs users host; };
          modules = [ ./nix/configuration.nix ];
        }
      ) hosts;

      homeConfigurations = builtins.mapAttrs (
        name: user:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs user; };
          modules = [ ./nix/home-manager/home.nix ];
        }
      ) users;
      # Also register home-manager configs for `nix flake check`.
      checks."${system}" = builtins.mapAttrs (name: config: config.activationPackage) homeConfigurations;

      devShells.${system}.default = import ./nix/devshell.nix { inherit pkgs; };
    };
}
