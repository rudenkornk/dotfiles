{ pkgs, ... }:

# Nix-related tools.
{
  home.packages = with pkgs; [
    dconf2nix
    home-manager
    nh
    nix-diff
    nix-index
    nix-melt
    nix-output-monitor
    nix-top
    nix-tree
  ];

  home.shellAliases = {
    nix-search-tv = ''command nix-search-tv print | fzf --prompt="Search NixOS> " --preview 'command nix-search-tv preview {}' --scheme history'';
  };

  programs.nix-search-tv = {
    enable = true;
  };
}
