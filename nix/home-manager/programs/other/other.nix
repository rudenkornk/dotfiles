{ pkgs, ... }:

# Other useful tools.
{
  home = {
    packages = with pkgs; [
      asciinema
      dconf
      dconf-editor
      dos2unix
      gh
      hyperfine
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
