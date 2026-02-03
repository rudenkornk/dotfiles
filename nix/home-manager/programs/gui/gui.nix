{ pkgs, ... }:

# GUI apps.
{
  home.packages = with pkgs; [
    google-chrome
    libreoffice
    telegram-desktop
  ];

  programs.firefox = {
    enable = true;
  };
}
