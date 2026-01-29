{ pkgs, ... }:

# Other useful tools.
{
  home.packages = with pkgs; [
    asciinema
    dconf
    dconf-editor
    dos2unix
    gh
    hyperfine
    tldr
    wiki-tui
    xh
  ];
}
