{ pkgs, config, ... }:

# System, monitoring & system info tools.
{
  home.packages = with pkgs; [
    acpi
    alsa-utils
    brightnessctl
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
    playerctl
    sbctl
    sof-firmware
    sysstat
  ];

  home.file = pkgs.locallib.homefiles {
    inherit (config) xdg;
    path = ./configs;
  };
}
