{
  lib,
  pkgs,
  users,
  ...
}:

{
  virtualisation = {
    containers = {
      enable = true;
      containersConf = {
        settings = {
          containers = {
            http_proxy = false;
          };
        };
      };
    };
    podman = {
      enable = true;
      package = pkgs.locallib.with_secrets { pkg = pkgs.podman; };

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
    docker = {
      enable = true;
      package = pkgs.locallib.with_secrets {
        pkg = pkgs.docker;
        binary = "dockerd";
      };
    };
    libvirtd.enable = true;
  };

  programs.virt-manager.enable = true;

  users.users = builtins.mapAttrs (_name: _user: {
    extraGroups = [
      "docker"
      "libvirtd"
    ];
  }) users;

  systemd = {
    services.docker = {
      environment = {
        HOME = "/root";
        USERKIND = lib.mkDefault "default";
      };
    };
  };
}
