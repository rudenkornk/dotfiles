{ pkgs, ... }:

# GUI apps.
{
  home.packages = with pkgs; [
    google-chrome
    libreoffice
    telegram-desktop
  ];

  imports = [
    ./gui/flameshot.nix
    ./gui/gnome-shell.nix
    ./gui/kitty.nix
  ];
}
