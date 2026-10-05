{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.local.merge-config;
  mergeConfigLib = import ./lib.nix { inherit lib pkgs; };
in
{
  options = {
    local.merge-config = { inherit (mergeConfigLib.options) file; };
  };

  config = {
    systemd.user.services = lib.mapAttrs (
      _: file:
      let
        group = { inherit file; };
        dependencies = mergeConfigLib.dependencies group;
      in
      {
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
          ExecStart = lib.getExe (mergeConfigLib.mkScript group);
        };
      }
    ) (mergeConfigLib.groupFiles cfg);
  };
}
