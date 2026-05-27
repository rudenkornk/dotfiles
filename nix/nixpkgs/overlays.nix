# See also https://nixcademy.com/posts/mastering-nixpkgs-overlays-techniques-and-best-practice/
args:

let
  overlay_modules = import ./overlays/locallib/get_modules.nix null ./overlays;
  overlays = map (overlay: import overlay args) overlay_modules;
in
overlays
