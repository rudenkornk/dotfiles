{ pkgs, config, ... }:
{

  programs.television = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    # enableNushellIntegration = true;
  };

  home.file = pkgs.locallib.homefiles {
    inherit (config) xdg;
    path = ./television;
  };
}
