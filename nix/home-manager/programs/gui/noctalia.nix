{
  pkgs,
  config,
  lib,
  host,
  inputs,
  ...
}:

{
  programs.noctalia-shell = {
    enable = true;
    # For settings we need quirky merging with monitors config.
    # Colors and plugins are linked as-is.
    settings =
      let
        inherit (builtins) fromJSON readFile;
        main_settings = fromJSON (readFile ./noctalia/settings.json);
      in
      lib.recursiveUpdate main_settings (host.monitors.noctalia or { });
  };

  imports = [ inputs.noctalia.homeModules.default ];
}
