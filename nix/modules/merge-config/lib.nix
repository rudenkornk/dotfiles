{ lib, pkgs }:

{
  options = {
    files = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (_: {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether this configuration should be merged.";
            };
            mode = lib.mkOption {
              type = lib.types.enum [
                "block"
                "json"
              ];
              default = "block";
            };
            source = lib.mkOption {
              type = lib.types.either lib.types.path (lib.types.nonEmptyListOf lib.types.path);
            };
            marker = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            insertAfter = lib.mkOption {
              type = lib.types.str;
              default = "";
            };
            clearTarget = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            readOnlyTarget = lib.mkOption {
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
      description = "Systemd units that should start only after configurations have been merged.";
    };

    requiredBy = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Systemd units that require configurations to be merged.";
    };
  };

  hasFiles = cfg: lib.any (value: value.enable) (lib.attrValues cfg.files);

  mkScript =
    cfg:
    let
      mkCmd =
        target: value:
        let
          blockArgs = lib.optionalString (value.mode == "block") (
            lib.optionalString (value.marker != null) "--marker ${lib.escapeShellArg value.marker} "
            + lib.optionalString (
              value.insertAfter != ""
            ) "--insert-after ${lib.escapeShellArg value.insertAfter} "
          );
          sources = lib.concatMapStringsSep " " lib.escapeShellArg (lib.toList value.source);
        in
        "${lib.getExe pkgs.custom.merge-config} ${value.mode} "
        + "--retry-decrypt --suppress-decrypt-errors "
        + blockArgs
        + lib.optionalString value.clearTarget "--clear-target "
        + lib.optionalString value.readOnlyTarget "--read-only-target "
        + "--source ${sources} --target ${lib.escapeShellArg target} || true";
    in
    pkgs.writeShellApplication {
      name = "merge-configs";
      runtimeInputs = [ pkgs.custom.merge-config ];
      text = ''
        echo "Merging configurations..."

      ''
      + lib.concatStringsSep "\n" (
        lib.mapAttrsToList mkCmd (lib.filterAttrs (_: value: value.enable) cfg.files)
      );
    };
}
