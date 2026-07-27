# See also https://nixcademy.com/posts/mastering-nixpkgs-overlays-techniques-and-best-practice/
# NOTE: overlays apply in the order listed below (kept alphabetical).
args:

let
  overlay_files = [
    ./overlays/custom.nix
    ./overlays/fwupd.nix
    ./overlays/locallib.nix
    ./overlays/nur.nix
    ./overlays/sops.nix
    ./overlays/unstable.nix
    ./overlays/vim-plugins.nix
    ./overlays/wpa_supplicant.nix
  ];
in
map (overlay: import overlay args) overlay_files
