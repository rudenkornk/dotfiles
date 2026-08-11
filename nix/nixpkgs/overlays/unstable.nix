{ inputs, ... }: final: prev: {
  unstable = import inputs.nixpkgs-unstable {
    localSystem = prev.stdenv.hostPlatform.system;
    inherit (prev) config;
  };
}
