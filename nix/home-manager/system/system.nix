{ pkgs, ... }:

# System, monitoring & system info tools.
{
  home.packages = with pkgs; [
    acpi
    alsa-utils
    brightnessctl
    cups
    dbus
    ddcutil
    dmidecode
    e2fsprogs
    fastfetch
    htop-vim
    libcgroup
    lsb-release
    lsof
    mokutil
    ntfs3g
    nvtopPackages.full
    parted
    pavucontrol
    pciutils
    playerctl
    sbctl
    sof-firmware
    sysstat
    usbutils
  ];

  local = {
    home.file = {
      ".".source = ./configs;
    };
  };
}
