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
          blockArgs = lib.optionals (value.mode == "block") (
            lib.optionals (value.marker != null) [
              "--marker"
              value.marker
            ]
            ++ lib.optionals (value.insertAfter != "") [
              "--insert-after"
              value.insertAfter
            ]
          );

          args = [
            (lib.getExe pkgs.custom.merge-config)
            value.mode
            "--retry-decrypt"
            "--suppress-decrypt-errors"
          ]
          ++ blockArgs
          ++ lib.optional value.clearTarget "--clear-target"
          ++ lib.optional value.readOnlyTarget "--read-only-target"
          ++ [
            "--target"
            target
            "--source"
          ]
          ++ map toString (lib.toList value.source);
        in
        "${lib.escapeShellArgs args} || true";
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
