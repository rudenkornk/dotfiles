{ pkgs, ... }:

# Remote desktop and remote filesystem tools.
{
  home.packages = with pkgs; [
    cifs-utils
    coder
    openssh
    samba
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
