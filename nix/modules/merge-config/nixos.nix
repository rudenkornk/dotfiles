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
    systemd.services = lib.mapAttrs (
      _: file:
      let
        group = { inherit file; };
      in
      {
        inherit (mergeConfigLib.dependencies group) before requiredBy;
        description = "Merge managed configuration into mutable files";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Environment = "HOME=/root";
          ExecStart = lib.getExe (mergeConfigLib.mkScript group);
        };
      }
    ) (mergeConfigLib.groupFiles cfg);
  };
}
