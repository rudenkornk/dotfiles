# System, monitoring & system info tools.
{ config, ... }:
let
  flakeCfg = config;
in
{
  flake = {
    # htop reads its config from $HTOPRC; the wrapper bakes the shared
    # `_configs` file, which also backs `/etc/htoprc` for root
    # (see modules/nixos/programs.nix).
    wrappers.htop = { wlib, pkgs, ... }: {
      imports = [ wlib.modules.default ];
      package = pkgs.htop-vim;
      env.HTOPRC = "${./_configs/.config/htop/htoprc}";
    };

    modules.homeManager.base = { pkgs, ... }: {
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
        flakeCfg.flake.packages.${pkgs.stdenv.hostPlatform.system}.htop
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
      ];
    };
  };
}
