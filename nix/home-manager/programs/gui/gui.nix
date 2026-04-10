{ pkgs, config, ... }:

# GUI apps.
{
  home.packages = with pkgs; [
    google-chrome
    libreoffice
    prismlauncher
    telegram-desktop
  ];

  programs.firefox = {
    enable = true;
  };

  home.file = pkgs.locallib.homefiles {
    inherit (config) xdg;
    path = ./configs;
  };
}
