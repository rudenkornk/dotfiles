{ lib, pkgs }:

{
  options = {
    links = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (_: {
          options = {
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

  hasLinks = cfg: cfg.links != { };

  mkScript =
    cfg:
    let
      mkCmd =
        target: v:
        "${lib.getExe pkgs.custom.sops-cached} "
        + "--retry "
        + "--symlink ${lib.escapeShellArg target} "
        + "${lib.optionalString v.recursive " --recurse"} "
        + "${lib.escapeShellArg v.source} ";
    in
    pkgs.writeShellApplication {
      name = "decrypt-secrets";
      runtimeInputs = [ pkgs.custom.sops-cached ];
      text = ''
        # Attempt to decrypt all secrets even if some fail.
        set +o errexit
        echo "Decrypting secrets..."

      ''
      + lib.concatStringsSep "\n" (lib.mapAttrsToList mkCmd cfg.links);
    };
}
