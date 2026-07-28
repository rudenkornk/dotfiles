_: final: prev:

{
  locallib = builtins.mapAttrs (name: value: import value { pkgs = final; }) {
    homefiles = ./locallib/homefiles.nix;
    secrets = ./locallib/secrets.nix;
  };
}
