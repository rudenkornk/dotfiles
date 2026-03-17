{ pkgs, config, ... }:

# System, monitoring & system info tools.
{
  home.packages = with pkgs; [
    acpi
    alsa-utils
    cups
    dbus
    htop-vim
    libcgroup
    lsb-release
    lsof
    neofetch
    ntfs3g
    nvtopPackages.full
    parted
    pavucontrol
    pciutils
    sbctl
    sof-firmware
    sysstat
  ];

  home.file = pkgs.locallib.homefiles {
    inherit (config) xdg;
    path = ./configs;
  };
}
