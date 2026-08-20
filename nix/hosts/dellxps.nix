{
  name = "dellxps";
  hardware-configuration = { inputs, ... }:

  {
    imports = [ inputs.nixos-hardware.nixosModules.dell-xps-15-9510-nvidia ];

    boot = {
      kernel = {
        sysctl = {
          "vm.swappiness" = 10; # Plenty of RAM allows reducing swap usage.
        };
      };
    };

    hardware = {
      facter = {
        reportPath = ./dellxps/facter.json;
        detected = {
          # NetworkManager already manages DHCP; facter defaults would enable second DHCP client.
          dhcp.enable = false;
          # The report records the proprietary `nvidia` driver for the discrete GPU,
          # and the facter graphics module would put it into `boot.initrd.kernelModules`,
          # which breaks the regular nvidia driver setup. Pin early KMS to the iGPU only.
          # See https://github.com/NixOS/nixpkgs/issues/485579
          boot.graphics.kernelModules = [ "i915" ];
        };
      };

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
      "eDP-1" = {
        mode = "3456x2160@60.001";
        scale = 1.333;
        position = {
          x = 0;
          y = 0;
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
    cudaSupport = true;
  };
}
