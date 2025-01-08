{
  description = "rudenkornk's dotfiles";

  # Flake inputs
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Flake outputs
  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations = {
        rudenkornk = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./nix/home-manager/home.nix ];
        };
      };
    };
}
