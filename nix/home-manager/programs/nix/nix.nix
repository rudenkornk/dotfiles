{ pkgs, ... }:

# Nix-related tools.
{
  home.packages = with pkgs; [
    cachix
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

  programs.nix-search-tv = {
    enable = true;
    enableTelevisionIntegration = true;
  };
}
