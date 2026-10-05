{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.local.secrets;
  secretsLib = import ./lib.nix { inherit lib pkgs; };
  dependencies = secretsLib.dependencies cfg;
in
{
  options = {
    local.secrets = { inherit (secretsLib.options) file; };
  };

  config = lib.mkIf (secretsLib.hasFiles cfg) {
    systemd.user.services.decrypt-secrets = {
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
        ExecStart = lib.getExe (secretsLib.mkScript cfg);
      };
    };
  };
}
