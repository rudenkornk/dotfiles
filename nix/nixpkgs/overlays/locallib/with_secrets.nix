{ pkgs, ... }:

{
  pkg,
  binary ? pkg.meta.mainProgram,
  extraSecrets ? [ ],
  extraScript ? "",
  ...
}:

let
  bash_secrets = import ./bash_secrets.nix { inherit pkgs; };
  extra_secrets_loaded = map (secret: ''
    # shellcheck source=/dev/null
    source "$(${pkgs.sops-cached}/bin/sops-cached ${secret})"
  '') extraSecrets;
  extra_secrets_script = builtins.concatStringsSep "\n" extra_secrets_loaded;
in
pkgs.writeScriptBin binary ''
  #!${pkgs.stdenv.shell}

  ${bash_secrets}
  ${extra_secrets_script}
  ${extraScript}

  exec ${pkg}/bin/${binary} "$@"
''
