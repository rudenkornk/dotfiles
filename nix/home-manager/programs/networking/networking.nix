{ pkgs, ... }:

# Networking tools.
{
  home.packages = with pkgs; [
    iptables
    iputils
    lftp
    ntp
  ];
}
