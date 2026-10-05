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
    systemd.services = lib.mapAttrs (
      _: file:
      let
        group = { inherit file; };
      in
      {
        inherit (secretsLib.dependencies group) before requiredBy;
        description = "Decrypt SOPS secrets to tmpfs and symlink them into place";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Environment = "HOME=/root";
          ExecStart = lib.getExe (secretsLib.mkScript group);
        };
      }
    ) (secretsLib.groupFiles cfg);
  };
}
