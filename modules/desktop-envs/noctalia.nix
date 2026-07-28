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
        # Noctalia mutates its settings at runtime, so the merged settings are
        # copied into place as a regular writable file instead of a store
        # symlink (see `home.activation` below). Runtime changes survive until
        # the next activation; `dotfiles gui` captures them back into the repo.
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

      home.activation.noctaliaSettings =
        let
          main_settings = fromJSON (readFile ./_noctalia/settings.json);
          nix_settings = lib.recursiveUpdate main_settings (config.local.host.monitors.noctalia or { });
          settingsFile = toJson "noctalia-settings.json" nix_settings;
        in
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p "${config.xdg.configHome}/noctalia"
          run install -m 0644 ${settingsFile} "${config.xdg.configHome}/noctalia/settings.json"
        '';
    };
}
