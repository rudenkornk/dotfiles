# Note: overlays cannot accept `pkgs` as an argument, since
# it will lead to infinite recursion.
args:

let
  overlay_modules = builtins.attrValues (import ./overlays/locallib/get_modules.nix null ./overlays);
  overlays = map (overlay: import overlay args) overlay_modules;
in
overlays
