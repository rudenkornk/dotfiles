# Standalone packages installed outside the main configurations
# (corp tooling fetched as prebuilt binaries).
{
  perSystem = { pkgs, ... }: {
    packages = {
      arc = pkgs.callPackage ./_src/arc.nix { };
      itsme-cli = pkgs.callPackage ./_src/itsme-cli.nix { };
      openvpn-ya = pkgs.callPackage ./_src/openvpn-ya.nix { };
      skotty = pkgs.callPackage ./_src/skotty.nix { };
      splitty = pkgs.callPackage ./_src/splitty.nix { };
      ya = pkgs.callPackage ./_src/ya.nix { };
    };
  };
}
