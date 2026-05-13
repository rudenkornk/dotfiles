{ host, ... }:

{
  fileSystems = {
    "/persistent".neededForBoot = true;
    "/nix".neededForBoot = true;
  };

  disko.devices = {
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "defaults"
        "size=8G"
        "mode=755"
      ];
    };

    disk.main = {
      inherit (host.disk) device;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };
          swap = {
            size = host.disk.swapSize or "64G";
            content = {
              type = "luks";
              name = "swap";
              settings.allowDiscards = true;
              content = {
                type = "swap";
              };
            };
          };
          root = {
            size = "100%";
            content = {
              type = "luks";
              name = "root";
              settings.allowDiscards = true;
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/persistent" = {
                    mountpoint = "/persistent";
                    mountOptions = [
                      "subvol=persistent"
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "subvol=nix"
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  preservation = {
    enable = true;
    preserveAt."/persistent" = {
      directories = [
        "/home"
        "/root"
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
        "/var/cache"
        "/var/db"
        "/var/lib"
        "/var/log"
        "/var/spool"
        "/etc/NetworkManager/system-connections"
      ];
      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];
    };
  };

  # systemd-machine-id-commit.service would fail, but it is not relevant
  # in this specific setup for a persistent machine-id so we disable it.
  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
}
