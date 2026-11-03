{ users, ... }:

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

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
    docker = {
      enable = true;
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
}
