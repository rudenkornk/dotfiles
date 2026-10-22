{ pkgs, ... }:

{
  pkg,
  binary ? null,
  extraSecrets ? [ ],
  extraScript ? "",
  ...
}:

pkgs.lib.makeOverridable (
  overrides:
  let
    inherit (pkgs) lib;
    inherit (lib) getExe getExe';
    package = if overrides == { } then pkg else pkg.override overrides;
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

    packageIdentity = {
      inherit (package) name;
    }
    // lib.optionalAttrs (package ? pname) { inherit (package) pname; }
    // lib.optionalAttrs (package ? version) { inherit (package) version; };
    packageMeta = builtins.removeAttrs (package.meta or { }) [ "outputsToInstall" ] // {
      mainProgram = package.meta.mainProgram or binaryName;
    };
    packagePaths = lib.unique (
      [ package ] ++ map (output: lib.getOutput output package) (package.meta.outputsToInstall or [ ])
    );
    extraOutputNames = builtins.filter (output: output != (package.outputName or "out")) (
      package.outputs or [ "out" ]
    );
    forwardedOutputs = lib.genAttrs extraOutputNames (output: package.${output});

    rewriteServiceFiles =
      # bash
      ''
        shopt -s nullglob
        for directory in "$out"/{etc,lib,share}/systemd/{system,user}; do
          for unit in "$directory"/*.service; do
            if grep -Fq -- "$original" "$unit" || grep -Fq -- "$resolved" "$unit"; then
              substitute "$unit" "$unit.wrapped" \
                --replace-quiet "$original" "$out/bin/${binaryName}" \
                --replace-quiet "$resolved" "$out/bin/${binaryName}"
              mv "$unit.wrapped" "$unit"
            fi
          done
        done
      '';
  in
  pkgs.symlinkJoin (
    packageIdentity
    // {
      meta = packageMeta;
      paths = packagePaths;
      passthru = (package.passthru or { }) // forwardedOutputs;
      postBuild = ''
        original=${lib.escapeShellArg binaryPath}
        resolved=$(readlink -f "$original")
        rm "$out/bin/${binaryName}"
        ln -s ${getExe launcher} "$out/bin/${binaryName}"

      ''
      + rewriteServiceFiles;
    }
  )
) { }
