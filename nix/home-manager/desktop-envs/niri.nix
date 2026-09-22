{
  pkgs,
  config,
  lib,
  host,
  ...
}:

let
  externalAbove = host.monitors.externalAbove or null;
  mkMonitorKdl =
    name: cfg: # kdl
    ''
      output "${name}" {
        mode "${cfg.mode}"
        ${lib.optionalString (
          cfg ? position
        ) "position x=${toString cfg.position.x} y=${toString cfg.position.y}"}
        scale ${toString cfg.scale}
      }
    '';
  outputsKdl = lib.concatStringsSep "\n" (
    lib.mapAttrsToList mkMonitorKdl (host.monitors.niri or { })
  );
in
{
  home.packages = with pkgs; [
    brightnessctl # Brightness control.
    ddcutil # Brightness control for external monitors.
    gnome-keyring # Secret manager.
    playerctl # Media control.
    polkit_gnome # Permission prompts.
    wireplumber # Volume control.
    wtype # Wayland key injection.
    xdg-desktop-portal-gnome # Screen sharing.
    xdg-desktop-portal-gtk # Screen sharing.
    xwayland-satellite # X11 proxy.
  ];

  systemd.user.services.niri-monitor-layout = lib.mkIf (externalAbove != null) {
    Unit = {
      Description = "Arrange external monitors above the laptop display";
      After = [ "niri.service" ];
      PartOf = [ "niri.service" ];
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.python3} ${config.xdg.configHome}/niri/monitor_layout.py ${externalAbove}";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  xdg = {
    configFile = {
      "niri/monitors.kdl".text = outputsKdl;

      "systemd/user/niri.service.d/override.conf".text =
        # toml
        ''
          [Service]
          # See https://github.com/niri-wm/niri/discussions/3734
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
