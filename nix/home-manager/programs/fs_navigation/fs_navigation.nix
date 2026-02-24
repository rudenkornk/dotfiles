{ pkgs, ... }:

# File management & search tools.
{
  home.packages = with pkgs; [
    bat
    dua
    dust
    fd
    file
    fzf
    hexyl
    ripgrep
    rsync
  ];
}
