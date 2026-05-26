{ pkgs, ... }:

# Other useful tools.
{
  home = {
    packages = with pkgs; [
      asciinema
      dos2unix
      hyperfine
      ldaps
      openldap
      stress
      stress-ng
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
