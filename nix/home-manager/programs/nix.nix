{ pkgs, get_modules, ... }:

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

  imports = get_modules ./nix;
}
