{ pkgs, ... }:

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
}
