{ pkgs, ... }:

# Fonts & graphics.
{
  home.packages = with pkgs; [
    (lib.hiPrio xorg.xvfb)
    corefonts
    fontconfig
    ncurses
    # CJK fonts for chinese, japanese, korean languages in Chrome.
    wqy_zenhei
    noto-fonts-cjk-sans
  ];
}
