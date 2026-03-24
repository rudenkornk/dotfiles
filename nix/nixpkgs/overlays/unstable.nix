{ inputs, ... }:
final: prev: { unstable = import inputs.nixpkgs_unstable { inherit (prev) system config; }; }
