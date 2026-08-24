{
  name = "dellxps";
  hardware-configuration = { inputs, ... }:

  {
    imports = [ inputs.nixos-hardware.nixosModules.dell-xps-15-9510-nvidia ];

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
    device = "/dev/disk/by-path/pci-0000:00:0e.0-pci-10000:e2:00.0-nvme-1";
  };
  monitors = {
    niri = import ./dellxps/niri_monitors.nix;
    noctalia = import ./dellxps/noctalia_monitors.nix;
  };
  gpu = {
    cudaSupport = true;
  };
}
