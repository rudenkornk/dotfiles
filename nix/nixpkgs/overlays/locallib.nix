_: final: prev:

let
  lib_modules = import ./locallib/get_modules.nix null ./locallib;
  locallib = builtins.mapAttrs (name: value: import value { pkgs = final; }) lib_modules;
in
{
  inherit locallib;
}
