{
  flake.modules.homeManager.base =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (builtins) fromJSON readFile;
      toJson = (pkgs.formats.json { }).generate;
    in
    {
      home = {
        packages = with pkgs; [
          noctalia-shell
          # https://docs.noctalia.dev/v4/getting-started/installation/#dependencies-explained
          bluez # Bluetooth support.
          brightnessctl # Brightness control.
          cliphist # Clipboard history support.
          ddcutil # Brightness control for external monitors.
          evolution-data-server # Calendar events.
          # NOTE: git (needed for update checking and the plugin system) comes
          # wrapped with its config from `modules/vcs/git.nix`.
          imagemagick # Template processing & wallpaper resizing.
          power-profiles-daemon # Power profile selection.
          python3 # Template processing & calendar events.
          upower # Battery state.
          wlsunset # Night light functionality.
          xdg-desktop-portal # Screen sharing and file picker functionality.
        ];
      };

      xdg = {
        configFile = {
          "noctalia/settings.json".source =
            let
              main_settings = fromJSON (readFile ./_noctalia/settings.json);
              nix_settings = lib.recursiveUpdate main_settings (config.local.host.monitors.noctalia or { });
            in
            toJson "noctalia-settings.json" nix_settings;
        };
      };
    };
}
