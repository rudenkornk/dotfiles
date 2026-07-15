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
        # p16v actually, p15v is the closest one available in the list.
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p15v-intel-gen3
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
        kernelParams = [ "snd_intel_dspcfg.dsp_driver=3" ];
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware = {
        cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

        logitech.wireless = {
          enable = true;
          enableGraphical = true;
        };
      };
      environment = {
        etc = {
          "ssl/certs/allCAs.pem".source = pkgs.locallib.secrets + /corp/allCAs.pem;
        };
      };
      local = {
        secrets = {
          links = {
            "/etc/NetworkManager/system-connections/YTeam.nmconnection".source =
              pkgs.locallib.secrets + /corp/YTeam.nmconnection.sops;
            "/run/user/0/secrets/rudenkornk.pem".source = pkgs.locallib.secrets + /corp/rudenkornk.pem.sops;
          };
          before = [
            "NetworkManager.service"
          ];
        };
      };
    };

  ramGiB = 32;
  disk = {
    device = "/dev/nvme1n1";
  };
  monitors = {
    niri = {
      "eDP-1" = {
        mode = "3840x2400@60.000";
        scale = 1.333;
        position = {
          x = 0;
          y = 0;
        };
        external = false;
        i2c-bus = "/dev/i2c-12";
      };
    };
  };
}
