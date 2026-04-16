{ pkgs, ... }:

{
  pkg,
  binary ? null,
  extraSecrets ? [ ],
  extraScript ? "",
  ...
}:

let
  inherit (pkgs.lib) getExe getExe';
  bash_secrets = import ./bash_secrets.nix { inherit pkgs; };
  extra_secrets_loaded = map (secret: ''
    # shellcheck source=/dev/null
    source "$(${getExe pkgs.sops-cached} ${secret})"
  '') extraSecrets;
  extra_secrets_script = builtins.concatStringsSep "\n" extra_secrets_loaded;
  pkg_bin_path = if (binary == null) then (getExe pkg) else (getExe' pkg binary);
  pkg_bin = builtins.baseNameOf pkg_bin_path;
in
pkgs.writeScriptBin pkg_bin ''
  #!${pkgs.stdenv.shell}

  ${bash_secrets}
  ${extra_secrets_script}
  ${extraScript}

  exec ${pkg_bin_path} "$@"
''
