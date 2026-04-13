{
  pkgs,
  config,
  lib,
  host,
  ...
}:

let
  mkOutputsKdl =
    name: cfg: # kdl
    ''
      output "${name}" {
        mode "${cfg.mode}"
        position x=${toString cfg.position.x} y=${toString cfg.position.y}
        scale ${toString cfg.scale}
      }
    '';
  outputsKdl = lib.concatStringsSep "\n" (lib.mapAttrsToList mkOutputsKdl host.monitors.niri);

  # Workaround for https://github.com/caelestia-dots/shell/issues/1341
  brightnessStep = toString 5;
  externalMonitors = lib.filterAttrs (name: cfg: cfg.external) host.monitors.niri;
  mkDdcCmd =
    name: cfg:
    lib.concatStringsSep " " [
      "ddcutil"
      "--noverify"
      "--enable-dynamic-sleep"
      "--sleep-multiplier=0.05"
      "--bus"
      (lib.last (lib.splitString "-" cfg.i2c-bus))
      "setvcp"
      "10" # VCP code for brightness.
    ];
  mkDdcCmdPlus = name: cfg: (mkDdcCmd name cfg) + " + " + brightnessStep + ";";
  mkDdcCmdMinus = name: cfg: (mkDdcCmd name cfg) + " - " + brightnessStep + ";";
  ddcCmdsPlus = lib.concatStringsSep " " (lib.mapAttrsToList mkDdcCmdPlus externalMonitors);
  ddcCmdsMinus = lib.concatStringsSep " " (lib.mapAttrsToList mkDdcCmdMinus externalMonitors);
  monitorsKdl = # kdl
    ''
      ${outputsKdl}

      binds {
        XF86MonBrightnessUp allow-when-locked=true {
            spawn-sh "brightnessctl --class=backlight set ${brightnessStep}%+; ${ddcCmdsPlus}"
        }
        XF86MonBrightnessDown allow-when-locked=true {
            spawn-sh "brightnessctl --class=backlight set ${brightnessStep}%-; ${ddcCmdsMinus}"
        }
      }
    '';

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
