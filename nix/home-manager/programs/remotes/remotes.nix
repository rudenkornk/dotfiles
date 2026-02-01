{ pkgs, ... }:

# Remote desktop, corporate tooling & VPNs.
{
  home.packages = with pkgs; [
    coder
    openconnect
    openldap
    openssh
    openvpn
    throne
  ];

  home = {
    file = {
      ".ssh" = {
        source = pkgs.locallib.secrets + /ssh;
        recursive = true;
      };
    };
  };
}
