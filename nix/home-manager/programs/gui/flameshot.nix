{ pkgs, ... }:
{
  home.packages = with pkgs; [
    wl-clipboard
    xdg-desktop-portal-gnome
    xdg-desktop-portal
  ];

  services.flameshot = {
    enable = true;
  };
}
