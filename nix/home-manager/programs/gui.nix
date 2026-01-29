{ pkgs, get_modules, ... }:

# GUI apps.
{
  home.packages = with pkgs; [
    google-chrome
    libreoffice
    telegram-desktop
  ];

  imports = get_modules ./gui;
}
