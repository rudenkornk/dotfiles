{ pkgs, ... }:

# System, monitoring & system info tools.
{
  home.packages = with pkgs; [
    acpi
    alsa-utils
    cups
    dbus
    htop-vim
    lsb-release
    lsof
    neofetch
    ntfs3g
    nvtopPackages.full
    pavucontrol
    pciutils
    sbctl
    sof-firmware
    sysstat
  ];
}
