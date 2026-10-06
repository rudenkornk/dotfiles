{ pkgs, ... }:

{
  Unit.Description = "Preload Bash secrets into the SOPS cache";
  Install.WantedBy = [ "default.target" ];
  Service = {
    Type = "exec"; # Let the session start before decryption finishes.
    RemainAfterExit = true;
    ExecStart = pkgs.writeShellScript "preload-bash-secrets" pkgs.locallib.bash_secrets;
  };
}
