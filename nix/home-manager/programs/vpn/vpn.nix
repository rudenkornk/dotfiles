{ pkgs, ... }:

# VPN clients and related tooling.
{
  home.packages = with pkgs; [
    openvpn
    custom.openconnect_corp
    custom.openvpn_corp
    custom.sing-box-run
    custom.throne-run
    openconnect
    sing-box
    throne
  ];
}
