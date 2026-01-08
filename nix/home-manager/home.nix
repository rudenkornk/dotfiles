{ user, pkgs, ... }:

{
  home = {
    inherit (user) username;
    homeDirectory = "/home/${user.username}";
    sessionVariables = {
      USERKIND = user.userkind;
    };

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "25.11"; # Did you read the comment?

    file = {
      ".config" = {
        source = ./configs/.config;
        recursive = true;
      };
      ".copilot/mcp-config.json".source = ./configs/.copilot/mcp-config.json;
      ".groovylintrc.json".source = ./configs/.groovylintrc.json;
      ".isort.cfg".source = ./configs/.isort.cfg;
      ".markdownlint.yaml".source = ./configs/.markdownlint.yaml;
      ".pydocstyle".source = ./configs/.pydocstyle;

      ".ssh" = {
        source = ./secrets/ssh;
        recursive = true;
      };
    };
  };

  fonts.fontconfig.enable = true;

  nixpkgs.overlays = [ (import ./nixpkgs/overlays/sops-cached.nix) ];

  imports = [
    ./dconf/settings.nix
    ./home/packages.nix
    ./home/shellAliases.nix
    ./programs/atuin.nix
    ./programs/docker-cli.nix
    ./programs/eza.nix
    ./programs/fish.nix
    ./programs/git.nix
    ./programs/gnome-shell.nix
    ./programs/kitty.nix
    ./programs/lazygit.nix
    ./programs/mypy.nix
    ./programs/neovim.nix
    ./programs/nix-search-tv.nix
    ./programs/oh-my-posh.nix
    ./programs/ruff.nix
    ./programs/tmux.nix
    ./programs/yazi.nix
    ./programs/zoxide.nix
    ./services/flameshot.nix
  ];
}
