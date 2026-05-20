{ pkgs, config, ... }:

# GUI apps.
{
  home = {
    packages = with pkgs; [
      libreoffice
      prismlauncher
      telegram-desktop
      qbittorrent
    ];

    file = pkgs.locallib.homefiles {
      inherit (config) xdg;
      path = ./configs;
    };
  };

}
