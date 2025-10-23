{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fish_plugin_autopair = {
      url = "github:jorgebucaran/autopair.fish";
      flake = false;
    };
    fish_plugin_puffer = {
      url = "github:nickeb96/puffer-fish";
      flake = false;
    };
    fish_plugin_fzf = {
      url = "github:patrickf1/fzf.fish";
      flake = false;
    };
    tmux_plugin_kanagawa = {
      url = "github:Nybkox/tmux-kanagawa";
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
          allowUnfree = true;
        };
      };
    in
    {
      nixosConfigurations.default = lib.nixosSystem {
        inherit system pkgs;
        specialArgs = { inherit inputs; };
        modules = [ ./nix/configuration.nix ];
      };
      homeConfigurations = {
        rudenkornk = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
            username = "rudenkornk";
          };
          modules = [ ./nix/home-manager/home.nix ];
        };
        rudenkornk_corp = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
            username = "rudenkornk_corp";
          };
          modules = [ ./nix/home-manager/home.nix ];
        };
      };
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          # Bootstrap python & python packages.
          python313
          uv

          # Tools for dumping gnome settings.
          dconf
          dconf2nix

          # Format & lint tools.
          fish
          git
          gitleaks
          markdownlint-cli
          nixfmt
          nodejs
          prettier
          ruff
          shellcheck
          shfmt
          statix
          stylua
          typos
        ];

        shellHook = ''
          uv sync
          source .venv/bin/activate
          echo "Welcome to the project devshell!"
        '';
      };
    };
}
