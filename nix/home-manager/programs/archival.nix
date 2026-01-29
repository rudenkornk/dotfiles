{ pkgs, ... }:

# Archival tools.
{
  home.packages = with pkgs; [
    bzip2
    gnutar
    gzip
    libarchive
    p7zip
    unar
    unrar
    unzip
    xz
    zip
  ];
}
