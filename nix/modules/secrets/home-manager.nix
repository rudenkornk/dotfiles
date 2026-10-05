{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.local.secrets;
  secretsLib = import ./lib.nix { inherit lib pkgs; };
in
{
  options = {
    local.secrets = { inherit (secretsLib.options) file; };
  };

  config = {
    systemd.user.services = lib.mapAttrs (
      _: file:
      let
        group = { inherit file; };
        dependencies = secretsLib.dependencies group;
      in
      {
        Unit = {
          Description = "Decrypt SOPS secrets to tmpfs and symlink them into place";
          Before = dependencies.before;
        };
        Install = {
          WantedBy = [ "default.target" ];
          RequiredBy = dependencies.requiredBy;
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = lib.getExe (secretsLib.mkScript group);
        };
      }
    ) (secretsLib.groupFiles cfg);
  };
}
