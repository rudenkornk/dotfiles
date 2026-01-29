{ pkgs, ... }:

# GUI apps.
{
  home.packages = with pkgs; [
    google-chrome
    libreoffice
    telegram-desktop
  ];

  imports = [
    ./gui/firefox.nix
    ./gui/flameshot.nix
    ./gui/gnome-shell.nix
    ./gui/kitty.nix
  ];
}
