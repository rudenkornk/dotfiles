{ pkgs, ... }:

# File management & search tools.
{
  home.packages = with pkgs; [
    ast-grep # Structural search-and-replace backend for grug-far.
    bat
    dua
    dust
    fd
    file
    hexyl
    ripgrep
    rsync
  ];
}
