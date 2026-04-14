{
  name = "thinkpad";
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
        # It is actually Lenovo ThinkPad P15s Gen 2i, but there is no such config in nixos-hardware.
        # p14s-intel-gen2 looks very similar, at least it has matching PCI bus ids.
        # I.e. on the real machine `lspci` output:
        # $ lspci
        # 00:02.0 VGA compatible controller: Intel Corporation TigerLake-LP GT2 [Iris Xe Graphics] (rev 01)
        # 01:00.0 3D controller: NVIDIA Corporation TU117GLM [Quadro T500 Mobile] (rev a1)
        # ...
        #
        # p14s-intel-gen2 config:
        # intelBusId = "PCI:0:2:0";
        # nvidiaBusId = "PCI:1:0:0";
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-intel-gen2
      ];

      boot = {
        initrd = {
          availableKernelModules = [
            "nvme"
            "rtsx_pci_sdmmc"
            "sd_mod"
            "thunderbolt"
            "usb_storage"
            "usbhid"
            "xhci_pci"
          ];
          kernelModules = [ ];
          luks.devices."luks-af224072-4e2b-4576-95c0-86df4fa2a40a".device =
            "/dev/disk/by-uuid/af224072-4e2b-4576-95c0-86df4fa2a40a";
          luks.devices."luks-eff1c0ef-9d50-4135-b042-7e283dbba58c".device =
            "/dev/disk/by-uuid/eff1c0ef-9d50-4135-b042-7e283dbba58c";
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
        device = "/dev/mapper/luks-af224072-4e2b-4576-95c0-86df4fa2a40a";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/DADD-39D5";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      swapDevices = [ { device = "/dev/mapper/luks-eff1c0ef-9d50-4135-b042-7e283dbba58c"; } ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };

  monitors = {
    niri = {
      "DP-3" = {
        mode = "2560x1440@59.951";
        scale = 1;
        position = {
          x = 0;
          y = 0;
        };
        external = true;
        i2c-bus = "/dev/i2c-16";
      };
      "eDP-1" = {
        mode = "3840x2160@60.000";
        scale = 1.333;
        position = {
          x = 0;
          y = 1440;
        };
        external = false;
        i2c-bus = "/dev/i2c-12";
      };
    };
    noctalia = import ./thinkpad/noctalia_monitors.nix;
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
