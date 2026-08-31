{
  config,
  lib,
  pkgs,
  user,
  ...
}:

{
  home = {
    packages = with pkgs; [
      cifs-utils
      coder
      openssh
      samba
    ];

    sessionVariables = {
      SSH_AUTH_SOCK = "${config.home.homeDirectory}/.ssh/agent.sock";
    };
  };

  local = {
    home.file = {
      ".".source = ./configs;
      ".ssh".source = pkgs.locallib.secrets + /ssh;
    };
  };

  systemd.user.services.ssh-agent-keys = {
    Unit = {
      Description = "SSH agent with sops-decrypted keys";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${lib.getExe (
        pkgs.writeShellApplication {
          name = "ssh-client";
          runtimeInputs = [
            pkgs.openssh
            pkgs.sops
          ];
          text = builtins.readFile ./scripts/ssh_client.sh;
        }
      )}";
    };
  };
}
