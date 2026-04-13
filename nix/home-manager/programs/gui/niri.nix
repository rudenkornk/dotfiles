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
        position x=${toString cfg.position.x} y=${toString cfg.position.y}
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
    xdg-desktop-portal-gnome # Screen sharing.
    xdg-desktop-portal-gtk # Screen sharing.
    xwayland-satellite # X11 proxy.
  ];

  xdg = {
    configFile = {
      "niri/monitors.kdl".text = outputsKdl;

      "systemd/user/niri.service.d/override.conf".text =
        let
          envList = lib.mapAttrsToList (name: value: "Environment=${name}=${value}") (
            host.gpu.offloadVars or { }
          );
          offloadLinesRaw = lib.concatStringsSep "\n" envList;
          offloadLines = if (host.gpu.niri.enable or false) then offloadLinesRaw else "";
        in
        # toml
        ''
          [Service]
          # See https://github.com/niri-wm/niri/discussions/3734
          UnsetEnvironment=SHLVL
          UnsetEnvironment=SHELL
          UnsetEnvironment=TERM
          UnsetEnvironment=PWD

          # GPU offload.
          ${offloadLines}
        '';
    };
  };

  gtk = {
    enable = true;
  };
}
