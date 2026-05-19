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
        };

        kernel = {
          sysctl = {
            "vm.swappiness" = 10; # Plenty of RAM allows reducing swap usage.
          };
        };
        kernelModules = [ "kvm-intel" ];
        extraModulePackages = [ ];
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware = {
        cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

        logitech.wireless = {
          enable = true;
          enableGraphical = true;
        };
      };
    };

  ramGiB = 64;
  disk = {
    device = "/dev/nvme1n1";
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
  gpu = {
    offloadVars = {
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __VK_LAYER_NV_optimus = "NVIDIA_only";
    };
    niri.enable = false;
  };
}
