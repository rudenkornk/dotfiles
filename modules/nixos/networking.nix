{
  flake.modules.nixos.base = { config, pkgs, ... }: {
    networking = {
      hostName = config.local.host.name;
      networkmanager = {
        enable = true;
        plugins = with pkgs; [
          networkmanager-openconnect
          networkmanager-openvpn
          networkmanager-ssh
        ];
      };
    };

    local = {
      secrets = {
        links = {
          "/etc/NetworkManager/system-connections/" = {
            source = pkgs.locallib.secrets + /nmconnections;
            recursive = true;
          };
        };
        before = [ "NetworkManager.service" ];
      };
    };
  };
}
