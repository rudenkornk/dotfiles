{
  name = "dellxps";
  hardware-configuration =
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
            "nvme"
            "rtsx_pci_sdmmc"
            "sd_mod"
            "thunderbolt"
            "usb_storage"
            "vmd"
            "xhci_pci"
          ];
          kernelModules = [ ];
          luks.devices."luks-adad80d8-7e75-42dd-866d-07a15c73d2ec".device =
            "/dev/disk/by-uuid/adad80d8-7e75-42dd-866d-07a15c73d2ec";
          luks.devices."luks-ff12b5a3-e0af-4db6-bf90-e8a8b5d912c7".device =
            "/dev/disk/by-uuid/ff12b5a3-e0af-4db6-bf90-e8a8b5d912c7";
        };

        kernel = {
          sysctl = {
            "vm.swappiness" = 10; # Plenty of RAM allows reducing swap usage.
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
    };

  monitors = {
    niri = {
      "DP-4" = {
        mode = "3840x2160@59.999";
        scale = 1;
        position = {
          x = 0;
          y = 0;
        };
        external = true;
        i2c-bus = "/dev/i2c-16";
      };
      "DP-6" = {
        mode = "3840x2160@59.996";
        scale = 1;
        position = {
          x = 3840;
          y = 0;
        };
        external = true;
        i2c-bus = "/dev/i2c-17";
      };
      "eDP-1" = {
        mode = "3456x2160@60.001";
        scale = 1.333;
        position = {
          x = 0;
          y = 2160;
        };
        external = false;
        i2c-bus = "/dev/i2c-12";
      };
    };
    noctalia = import ./dellxps/noctalia_monitors.nix;
  };
}
