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
  };

  programs = {
    firefox = {
      enable = true;
    };
  };

}
