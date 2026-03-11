{ pkgs, ... }:

# Fonts & graphics.
{
  home.packages = with pkgs; [
    (lib.hiPrio xorg.xvfb)
    cm_unicode
    corefonts
    fontconfig
    google-fonts
    ncurses
    noto-fonts
    paratype-pt-mono
    paratype-pt-sans
    paratype-pt-serif

    # CJK fonts for chinese, japanese, korean languages in Chrome.
    wqy_zenhei
    noto-fonts-cjk-sans
  ];
}
