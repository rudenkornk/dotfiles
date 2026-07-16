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
    local.secrets = { inherit (secretsLib.options) links before requiredBy; };
  };

  config = lib.mkIf (secretsLib.hasLinks cfg) {
    systemd.services.decrypt-secrets = {
      inherit (cfg) before requiredBy;
      description = "Decrypt SOPS secrets to tmpfs and symlink them into place";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Environment = "HOME=/root";
        ExecStart = lib.getExe (secretsLib.mkScript cfg);
      };
    };
  };
}
