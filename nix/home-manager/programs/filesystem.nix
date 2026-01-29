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

  imports = [
    ./filesystem/bat.nix
    ./filesystem/eza.nix
    ./filesystem/yazi.nix
    ./filesystem/zoxide.nix
  ];
}
