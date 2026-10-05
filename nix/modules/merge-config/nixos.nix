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

  config = lib.mkIf (mergeConfigLib.hasFiles cfg) {
    systemd.services.merge-config = {
        inherit (mergeConfigLib.dependencies cfg) before requiredBy;
        description = "Merge managed configuration into mutable files";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Environment = "HOME=/root";
          ExecStart = lib.getExe (mergeConfigLib.mkScript cfg);
        };
      };
  };
}
