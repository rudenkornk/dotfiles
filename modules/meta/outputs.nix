# Transitional module: standalone packages and dev shells still built from the
# pre-dendritic `nix/` tree.
# It is dissolved into feature modules over the course of the dendritic migration.
{ withSystem, ... }: {
  flake = {
    packages."x86_64-linux" = withSystem "x86_64-linux" (
      { pkgs, ... }:
      builtins.mapAttrs (_: path: pkgs.callPackage path { }) (
        pkgs.locallib.get_modules_map ../../nix/packages
      )
    );

    devShells."x86_64-linux" = withSystem "x86_64-linux" (
      { pkgs, ... }: import ../../nix/devshell.nix { inherit pkgs; }
    );
  };
}
