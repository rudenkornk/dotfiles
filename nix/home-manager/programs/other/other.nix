{ pkgs, ... }:

# Other useful tools.
{
  home = {
    packages = with pkgs; [
      asciinema
      custom.ldaps
      dos2unix
      hyperfine
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
