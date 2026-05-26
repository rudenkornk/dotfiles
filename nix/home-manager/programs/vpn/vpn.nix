{ pkgs, ... }:

# VPN clients and related tooling.
{
  home.packages = with pkgs; [
    ThroneRun
    openconnect
    openconnect_corp
    openvpn
    sing-box
    sing-box-run
    throne
  ];
}
