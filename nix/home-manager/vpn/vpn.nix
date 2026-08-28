{ pkgs, ... }:

# VPN clients and related tooling.
{
  home.packages = with pkgs; [
    openvpn
    custom.sing-box-run
    custom.throne-run
    openconnect
    sing-box
    throne
  ];
}
