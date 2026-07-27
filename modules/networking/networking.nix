{
  flake.modules.homeManager.base = { pkgs, ... }:
  # Networking tools.
  {
    home = {
      packages = with pkgs; [
        iptables
        iputils
        lftp
        ntp
        qbittorrent
        wireshark
      ];
    };
  };
}
