{ inputs, ... }:
final: prev: {
  unstable = import inputs.nixpkgs_unstable {
    localSystem = prev.stdenv.hostPlatform.system;
    inherit (prev) config;
  };
}
