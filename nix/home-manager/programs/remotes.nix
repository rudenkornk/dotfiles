{ pkgs, ... }:

# Remote desktop, corporate tooling & VPNs.
{
  home.packages = with pkgs; [
    coder
    openconnect
    openldap
    openvpn
    throne
  ];
}
