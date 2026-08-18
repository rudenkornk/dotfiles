# Custom secrets module, deliberately kept instead of the community sops-nix module (evaluated 2026-08).
# Rationale:
# - Decryption failures must be non-fatal: with a missing age key this module still activates cleanly,
#   whereas sops-nix fails `home-manager switch` outright and makes `nixos-rebuild switch` exit non-zero,
#   with no supported "continue without secrets" mode.
# - sops-nix has no decryption cache and re-decrypts on every activation and login,
#   currently even once per secret rather than per file (Mic92/sops-nix#956),
#   which is prohibitively slow with TPM-bound age keys; `sops-cached` decrypts each file once per boot.
# - Launch-time env injection (`with_secrets`, `bash_secrets`) has no sops-nix equivalent,
#   so most of the custom machinery would survive a migration anyway.
# - sops-nix age plugin support (required for the TPM keys) is young and unproven:
#   merged 2026-01, absent from the README, with no public `age-plugin-tpm` usage reports.
{ lib, pkgs }:

{
  options = {
    links = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (_: {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether this secret should be decrypted and linked.";
            };
            source = lib.mkOption { type = lib.types.path; };
            recursive = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
          };
        })
      );
      default = { };
    };

    before = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Systemd units that should start only after secrets have been decrypted.";
    };

    requiredBy = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Systemd units that require secrets to be decrypted.";
    };
  };

  hasLinks = cfg: lib.any (value: value.enable) (lib.attrValues cfg.links);

  mkScript =
    cfg:
    let
      mkCmd =
        target: v:
        "${lib.getExe pkgs.custom.sops-cached} "
        + "--retry "
        + "--symlink ${lib.escapeShellArg target} "
        + "${lib.optionalString v.recursive "--recursive "}"
        + "${lib.escapeShellArg v.source} || true";
    in
    pkgs.writeShellApplication {
      name = "decrypt-secrets";
      runtimeInputs = [ pkgs.custom.sops-cached ];
      text = ''
        echo "Decrypting secrets..."

      ''
      + lib.concatStringsSep "\n" (
        lib.mapAttrsToList mkCmd (lib.filterAttrs (_: value: value.enable) cfg.links)
      );
    };
}
