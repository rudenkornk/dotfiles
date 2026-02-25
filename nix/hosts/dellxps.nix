{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.dell-xps-15-9510-nvidia
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "vmd"
        "nvme"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      kernelModules = [ ];
      luks.devices."luks-adad80d8-7e75-42dd-866d-07a15c73d2ec".device =
        "/dev/disk/by-uuid/adad80d8-7e75-42dd-866d-07a15c73d2ec";
      luks.devices."luks-ff12b5a3-e0af-4db6-bf90-e8a8b5d912c7".device =
        "/dev/disk/by-uuid/ff12b5a3-e0af-4db6-bf90-e8a8b5d912c7";
    };

    kernel = {
      sysctl = {
        "vm.swappiness" = 10; # Plenty of RAM allows to reduce swap usage.
      };
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  fileSystems."/" = {
    device = "/dev/mapper/luks-adad80d8-7e75-42dd-866d-07a15c73d2ec";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/4CBE-362B";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ { device = "/dev/mapper/luks-ff12b5a3-e0af-4db6-bf90-e8a8b5d912c7"; } ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
  };
}
