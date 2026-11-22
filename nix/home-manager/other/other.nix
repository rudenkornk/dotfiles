{ config, pkgs, ... }:

# Other useful tools.
{
  home = {
    packages = with pkgs; [
      asciinema
      dos2unix
      gnome-solanum
      hyperfine
      openldap
      stress
      stress-ng
      tomato-c
      wiki-tui
      xh
    ];
  };

  programs = {
    tealdeer = {
      enable = true;
      settings.updates.auto_update = true;
    };
  };

  local = {
    home.file.".".source = ./configs;
    secrets = {
      file = {
        "${config.home.homeDirectory}/.kaggle/access_token" = {
          source = pkgs.locallib.secrets + /kaggle-access-token.sops;
          service-name = "decrypt-kaggle";
        };
      };
    };
  };
}
