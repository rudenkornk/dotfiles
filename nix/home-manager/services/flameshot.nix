{ pkgs, ... }:
{
  home.packages = with pkgs; [
    wl-clipboard
    xdg-desktop-portal-gnome
    xdg-desktop-portal
  ];

  services.flameshot = {
    enable = true;
    settings = {
      General = {
        contrastOpacity = 84;
        copyOnDoubleClick = true;
        disabledTrayIcon = true;
        drawThickness = 15;
        filenamePattern = "%Y-%b-%d-%Hh%Mm%Ss";
        insecurePixelate = true;
        predefinedColorPaletteLarge = true;
        saveLastRegion = true;
        showAbortNotification = false;
        showDesktopNotification = false;
        showStartupLaunchMessage = false;
        startupLaunch = true;
        undoLimit = 999;
      };
      Shortcuts = {
        TYPE_ACCEPT = "Ctrl+c";
        TYPE_CIRCLECOUNT = "c";
      };
    };
  };
}
