{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.local.merge-config;
  mergeConfigLib = import ./lib.nix { inherit lib pkgs; };
  dependencies = mergeConfigLib.dependencies cfg;
in
{
  options = {
    local.merge-config = { inherit (mergeConfigLib.options) file; };
  };

  config = lib.mkIf (mergeConfigLib.hasFiles cfg) {
    systemd.user.services.merge-config = {
        Unit = {
          Description = "Merge managed configuration into mutable files";
          Before = dependencies.before;
        };
        Install = {
          WantedBy = [ "default.target" ];
          RequiredBy = dependencies.requiredBy;
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = lib.getExe (mergeConfigLib.mkScript cfg);
        };
      };
  };
}
