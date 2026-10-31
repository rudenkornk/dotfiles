{ pkgs, ... }:

# VPN clients and related tooling.
{
  home = {
    packages = with pkgs; [
      custom.sing-box-run
      custom.throne-run
      custom.xray-run
      openconnect
      openvpn
      sing-box
      throne
    ];
  };
}
