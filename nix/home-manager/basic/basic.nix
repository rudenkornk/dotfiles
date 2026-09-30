{ pkgs, ... }:

# Basic tools.
{
  home.packages = with pkgs; [
    curl
    libnotify
    moreutils
    patch
    uutils-coreutils-noprefix
    vim
    wget
  ];
}
