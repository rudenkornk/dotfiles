{
  pkgs,
  config,
  lib,
  host,
  ...
}:

let
  mkMonitorKdl =
    name: cfg: # kdl
    ''
      output "${name}" {
        mode "${cfg.mode}"
        position x=${cfg.position.x} y=${cfg.position.y}
        scale ${cfg.scale}
      }
    '';
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

      # See https://github.com/niri-wm/niri/discussions/3734
      "systemd/user/niri.service.d/override.conf".text = ''
        [Service]
        UnsetEnvironment=SHLVL
        UnsetEnvironment=SHELL
        UnsetEnvironment=TERM
        UnsetEnvironment=PWD
      '';
    };
  };

  gtk = {
    enable = true;
  };
}
