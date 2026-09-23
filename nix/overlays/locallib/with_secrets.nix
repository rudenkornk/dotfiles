{ pkgs, ... }:

{
  pkg,
  binary ? null,
  extraSecrets ? [ ],
  extraScript ? "",
  ...
}:

(
  package:
  let
    inherit (pkgs) lib;
    inherit (lib) getExe getExe';
    binaryPath = if binary == null then getExe package else getExe' package binary;
    binaryName = builtins.baseNameOf binaryPath;

    secretsScript = import ./bash_secrets.nix { inherit pkgs; };
    extraSecretsScript = builtins.concatStringsSep "\n" (
      map (secret: ''
        # shellcheck source=/dev/null
        source "$(${getExe pkgs.custom.sops-cached} ${secret})"
      '') extraSecrets
    );
    launcher =
      pkgs.writeScriptBin binaryName
        # bash
        ''
          #!${pkgs.stdenv.shell}

          export PROXY_APP=${lib.escapeShellArg binaryName}
          ${secretsScript}
          ${extraSecretsScript}
          ${extraScript}

          exec ${binaryPath} "$@"
        '';
  in
  launcher
)
  pkg
