{ config, pkgs, ... }:

let
  ssh_keys = {
    ".ssh" = {
      source = pkgs.locallib.secrets + /ssh;
      recursive = true;
    };
  };
  ssh_configs = pkgs.locallib.homefiles {
    inherit (config) xdg;
    path = ./configs;
  };
in
{
  home = {
    packages = with pkgs; [
      cifs-utils
      coder
      openssh
      samba
    ];

    file = ssh_keys // ssh_configs;
  };
}
