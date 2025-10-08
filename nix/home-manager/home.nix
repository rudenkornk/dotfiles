{ config, pkgs, ... }:

{
  home = {
    packages = with pkgs; [ hello ];

    username = "rudenkornk";
    homeDirectory = "/home/rudenkornk";

    stateVersion = "25.05";
  };

  # Let home-manager install and manage itself.
  programs.home-manager.enable = true;
}
