{ pkgs, ... }:

# File management & search tools.
{
  home.packages = with pkgs; [
    ast-grep # Structural search-and-replace backend for grug-far.
    bat
    unstable.dua # TODO(rudenkornk): Switch to stable after NixOS 26.11.
    dust
    fd
    file
    hexyl
    ripgrep
    rsync
  ];

  local.home.file.".".source = ./configs;
}
