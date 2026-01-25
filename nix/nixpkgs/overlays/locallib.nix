_: final: prev:

let
  inherit (prev) lib;
  lib_modules = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (
    builtins.readDir ./locallib
  );
  locallib = lib.mapAttrs' (nix_module: _filetype: {
    name = lib.removeSuffix ".nix" nix_module;
    value = import ./locallib/${nix_module} { pkgs = final; };
  }) lib_modules;
in
{
  inherit locallib;
}
