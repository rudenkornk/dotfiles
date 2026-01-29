{ pkgs, ... }:

# System, monitoring & system info tools.
{
  home.packages = with pkgs; [
    alsa-utils
    dbus
    htop-vim
    lsb-release
    lsof
    neofetch
    ntfs3g
    nvtopPackages.full
    pavucontrol
    pciutils
    sof-firmware
    sysstat
  ];
}
