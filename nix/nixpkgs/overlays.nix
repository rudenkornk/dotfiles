# Note: overlays cannot accept `pkgs` as an argument, since
# it will lead to infinite recursion.
args:

let
  overlay_dir = builtins.readDir ./overlays;
  overlay_modules = builtins.filter (
    name:
    let
      type = overlay_dir.${name};
      isNixFile = (builtins.match ".*\\.nix" name) != null;
    in
    type == "regular" && isNixFile
  ) (builtins.attrNames overlay_dir);
  overlays = map (overlay: import ./overlays/${overlay} args) overlay_modules;
in
overlays
