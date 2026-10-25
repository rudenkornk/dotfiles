{ pkgs, ... }:

# Archival tools.
{
  home.packages = with pkgs; [
    bzip2
    file-roller
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
