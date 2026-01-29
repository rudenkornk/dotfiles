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

  imports = [ ./nix/nix-search-tv.nix ];
}
