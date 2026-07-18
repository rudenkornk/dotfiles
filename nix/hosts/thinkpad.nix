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
      services = {
        # Security spyware for corporate machine.
        osquery = {
          enable = true;
          flags = {
            # Main flags.
            # tls_hostname = <encrypted in EnvironmentFile>;
            tls_server_certs = "${pkgs.locallib.secrets + /corp/allCAs.pem}";
            disable_audit = "false";
            disable_extensions = "true";
            host_identifier = "uuid";

            # Daemon control flags.
            force = "true";
            watchdog_level = "-0";
            watchdog_utilization_limit = "30";

            # Enrollment flags.
            enroll_tls_endpoint = "/api/v1/osquery/enroll";
            enroll_secret_path = "/run/user/0/secrets/osquery/enroll_secret";
            tls_enroll_max_attempts = "22";

            # Configuration control flags.
            config_plugin = "tls";
            config_refresh = "300";
            config_tls_endpoint = "/api/v1/osquery/config";
            config_enable_backup = "true";

            # Distributed query service flags.
            disable_distributed = "false";
            distributed_interval = "14";
            distributed_tls_read_endpoint = "/api/v1/osquery/distributed/read";
            distributed_tls_write_endpoint = "/api/v1/osquery/distributed/write";

            # Logging/results flags.
            logger_plugin = "tls";
            # logger_path="/var/log/osquery"; # Already set to this path.
            logger_tls_endpoint = "/logger";
            logger_min_status = "10";
            logger_min_stderr = "10";
            stderrthreshold = "3";
          };
        };
      };
      systemd = {
        services = {
          osqueryd = {
            serviceConfig = {
              EnvironmentFile = "/run/user/0/secrets/osquery/environment_file";
              ReadOnlyPaths = [ "/" ];
              ReadWritePaths = [
                "/var/lib/osquery"
                "/run"
              ];

              InaccessiblePaths = [
                "-/home/rudenkornk/.config/chromium/"
                "-/home/rudenkornk/.config/google-chrome/"
                "-/home/rudenkornk/.config/mozilla/"
                "-/home/rudenkornk/.config/sops/"
                "-/home/rudenkornk/.gnupg/"
                "-/home/rudenkornk/.local/share/keyrings/"
                "-/home/rudenkornk/.local/share/TelegramDesktop/"
                "-/home/rudenkornk/.pki/"

                "-/home/rudenkornk_corp/.config/chromium/"
                "-/home/rudenkornk_corp/.config/google-chrome/"
                "-/home/rudenkornk_corp/.config/mozilla/"
                "-/home/rudenkornk_corp/.config/sops/"
                "-/home/rudenkornk_corp/.gnupg/"
                "-/home/rudenkornk_corp/.local/share/keyrings/"
                "-/home/rudenkornk_corp/.local/share/TelegramDesktop/"
                "-/home/rudenkornk_corp/.pki/"

                "-/root/.config/sops/"
                # "-/run/user/0/secrets/"
                "-/run/user/1000/secrets/"
                "-/run/user/1001/secrets/"
              ];
            };
            unitConfig = {
              ConditionFileNotEmpty = [
                "/run/user/0/secrets/osquery/enroll_secret"
                "/run/user/0/secrets/osquery/environment_file"
              ];
            };
          };
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
            "/run/user/0/secrets/osquery/enroll_secret".source =
              pkgs.locallib.secrets + /corp/osquery_enroll_secret.sops;
            "/run/user/0/secrets/osquery/environment_file".source =
              pkgs.locallib.secrets + /corp/osquery_environment_file.sops;
          };
          before = [
            "NetworkManager.service"
            "osqueryd.service"
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
