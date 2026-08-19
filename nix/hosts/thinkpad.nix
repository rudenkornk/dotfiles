{
  name = "thinkpad";
  hardware-configuration = { pkgs, ... }:

  {
    imports = [
      ./thinkpad/osquery.nix
      ./thinkpad/splitty.nix
    ];

    boot = {
      kernel = {
        sysctl = {
          "vm.swappiness" = 10; # Plenty of RAM allows reducing swap usage.
        };
      };
      kernelParams = [ "snd_intel_dspcfg.dsp_driver=3" ];
    };

    hardware = {
      facter = {
        reportPath = ./thinkpad/facter.json;
        # NetworkManager manages all interfaces itself, whereas facter's per-interface
        # `useDHCP = true` defaults would additionally enable dhcpcd as a second DHCP client.
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
          "/etc/NetworkManager/system-connections/YTeam.nmconnection".source =
            pkgs.locallib.secrets + /corp/YTeam.nmconnection.sops;
          "/run/user/0/secrets/rudenkornk.pem".source = pkgs.locallib.secrets + /corp/rudenkornk.pem.sops;
        };
        before = [ "NetworkManager.service" ];
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
    noctalia = import ./thinkpad/noctalia_monitors.nix;
  };
}
