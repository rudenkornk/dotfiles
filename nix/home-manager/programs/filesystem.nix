{ pkgs, get_modules, ... }:

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

  imports = get_modules ./filesystem;
}
