{
  pkgs,
  config,
  lib,
  host,
  inputs,
  ...
}:

let
  inherit (builtins) fromJSON readFile;
  toJson = (pkgs.formats.json { }).generate;
in
{
  home = {
    packages = with pkgs; [ unstable.noctalia-shell ];
  };

  xdg = {
    configFile = {
      "noctalia/settings.json".source =
        let
          main_settings = fromJSON (readFile ./noctalia/settings.json);
          nix_settings = lib.recursiveUpdate main_settings (host.monitors.noctalia or { });
        in
        toJson "noctalia-settings.json" nix_settings;
    };
  };
}
