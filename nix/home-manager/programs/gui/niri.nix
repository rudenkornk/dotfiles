{
  pkgs,
  config,
  lib,
  host,
  ...
}:

let
  mkMonitorKdl =
    name: cfg:
    lib.hm.generators.toKDL { } {
      output = {
        _args = [ name ];
        mode = {
          _args = [ cfg.mode ];
        };
        scale = {
          _args = [ cfg.scale ];
        };
        position = {
          _props = { inherit (cfg.position) x y; };
        };
      };
    };
  monitorsKdl = lib.concatStringsSep "\n" (lib.mapAttrsToList mkMonitorKdl host.monitors.niri);
in
{
  home.packages = with pkgs; [
    brightnessctl # Brightness control.
    gnome-keyring # Secret manager.
    playerctl # Media control.
    polkit_gnome # Permission prompts.
    wireplumber # Volume control.
    xdg-desktop-portal-gnome # Screen sharing.
    xdg-desktop-portal-gtk # Screen sharing.
    xwayland-satellite # X11 proxy.
  ];

  xdg = {
    configFile = {
      "niri/monitors.kdl".text = monitorsKdl;
    };
  };

  gtk = {
    enable = true;
  };
}
