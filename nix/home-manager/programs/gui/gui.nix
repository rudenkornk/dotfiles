{ pkgs, config, ... }:

# GUI apps.
{
  home = {
    packages = with pkgs; [
      google-chrome
      libreoffice
      prismlauncher
      telegram-desktop
    ];

    file = pkgs.locallib.homefiles {
      inherit (config) xdg;
      path = ./configs;
    };

    pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Amber";
      size = 32;
    };
  };

  gtk = {
    enable = true;
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Amber"; # Keep in sync with home.pointerCursor.name.
    };
  };

  programs = {
    firefox = {
      enable = true;
    };
  };

}
