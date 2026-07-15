{
  config,
  lib,
  pkgs,
  user,
  ...
}:

let
  ssh_keys = {
    ".ssh" = {
      source = pkgs.locallib.secrets + /ssh;
      recursive = true;
    };
  };
  ssh_configs = pkgs.locallib.homefiles {
    inherit (config) xdg;
    path = ./configs;
  };
in
{
  home = {
    packages = with pkgs; [
      cifs-utils
      coder
      openssh
      samba
    ];

    file = ssh_keys // ssh_configs;

    sessionVariables = {
      SSH_AUTH_SOCK = "${config.home.homeDirectory}/.ssh/agent.sock";
    };
  };

  local = {
    secrets.links =
      { }
      // lib.optionalAttrs (user.userkind == "corp") {
        "${config.home.homeDirectory}/.ssh/corp/config".source =
          pkgs.locallib.secrets + /corp/ssh_config.sops;
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
