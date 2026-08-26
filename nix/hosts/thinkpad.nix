{ pkgs, ... }:

let
  facterReportPath = ./thinkpad/facter.json;
  facter = pkgs.locallib.facter facterReportPath;
in
{
  name = "thinkpad";
  smbiosUUIDHash = "4cc3d7d1d69c8a0372d34bbbbebc4c82e1c5f22f";
  disk_device = "/dev/disk/by-path/pci-0000:05:00.0-nvme-1";

  hardware-configuration = { ... }:

  {
    imports = [
      ./thinkpad/osquery.nix
      ./thinkpad/splitty.nix
    ];

    boot = {
      kernelParams = [ "snd_intel_dspcfg.dsp_driver=3" ];
    };

    hardware = {
      facter = {
        reportPath = facterReportPath;
        # NetworkManager already manages DHCP; facter defaults would enable second DHCP client.
        detected.dhcp.enable = false;
      };

      trackpoint = {
        enable = true;
        emulateWheel = true;
        device = "TPPS/2 Elan TrackPoint";
      };
      graphics.extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
        vpl-gpu-rt
      ];

      logitech.wireless = {
        enable = true;
        enableGraphical = true;
      };
    };

    services.fstrim.enable = true;

    environment = {
      etc = {
        "ssl/certs/allCAs.pem".source = pkgs.locallib.secrets + /corp/allCAs.pem;
      };
    };
    local = {
      secrets = {
        links = {
          "/etc/NetworkManager/system-connections/corp_wifi.nmconnection".source =
            pkgs.locallib.secrets + /corp/corp_wifi.nmconnection.sops;
          "/run/user/0/secrets/rudenkornk.pem".source = pkgs.locallib.secrets + /corp/rudenkornk.pem.sops;
        };
        before = [ "NetworkManager.service" ];
      };
    };
  };

  inherit (facter) ramGiB;
  monitors = {
    niri = import ./thinkpad/niri_monitors.nix;
    noctalia = import ./thinkpad/noctalia_monitors.nix;
  };
  gpu = {
    cudaSupport = facter.hasNvidiaGpu;
  };
}
