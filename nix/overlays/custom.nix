_: final: prev:

let
  custom_modules = import ./locallib/get_modules_map.nix null ./custom;
  custom = builtins.mapAttrs (_name: value: import value final prev) custom_modules;
in
{
  inherit custom;
}
