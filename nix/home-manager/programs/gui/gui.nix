{ pkgs, ... }:

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
}
