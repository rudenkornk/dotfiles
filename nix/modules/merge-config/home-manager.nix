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
    local.merge-config = { inherit (mergeConfigLib.options) files before requiredBy; };
  };

  config = lib.mkIf (mergeConfigLib.hasFiles cfg) {
    systemd.user.services.merge-config = {
      Unit = {
        Description = "Merge managed configuration into mutable files";
        Before = cfg.before;
      };
      Install = {
        WantedBy = [ "default.target" ];
        RequiredBy = cfg.requiredBy;
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = lib.getExe (mergeConfigLib.mkScript cfg);
      };
    };
  };
}
