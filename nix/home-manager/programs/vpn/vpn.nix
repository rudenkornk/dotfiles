{ pkgs, ... }:

# VPN clients and related tooling.
{
  home.packages = with pkgs; [
    (openvpn.override { pkcs11Support = true; })
    custom.openconnect_corp
    custom.sing-box-run
    custom.throne-run
    openconnect
    sing-box
    throne
  ];
}
