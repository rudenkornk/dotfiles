_: final: prev:

{
  locallib = builtins.mapAttrs (name: value: import value { pkgs = final; }) {
    bash_secrets = ./locallib/bash_secrets.nix;
    homefiles = ./locallib/homefiles.nix;
    secrets = ./locallib/secrets.nix;
    with_secrets = ./locallib/with_secrets.nix;
  };
}
