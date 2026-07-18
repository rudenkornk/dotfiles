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
        "size=${toString (host.disk.tmpfsSizeGiB or ((host.ramGiB or 8) / 2))}G"
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
            size = "${toString (host.disk.swapSizeGiB or host.ramGiB or 32)}G";
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
        # All user home directories: dotfiles, shell history, SSH keys, user data.
        "/home"

        # sops age key used to decrypt secrets at runtime.
        "/root/.config/sops"

        # Saved Wi-Fi and VPN connection profiles (passwords, certificates).
        # Without this all networks must be reconfigured from scratch.
        # Kept alongside /var/lib/NetworkManager which holds NM's internal state.
        "/etc/NetworkManager/system-connections"

        # TPM pkcs11 database.
        "/etc/tpm2_pkcs11/"

        # System-level caches (cups, fwupd, libvirt, etc.).
        # Kept to avoid re-downloads on every boot; safe to drop if disk space is a concern.
        "/var/cache"

        # System logs. Required for `journalctl -b -1` and any cross-boot log analysis.
        "/var/log"

        # All persistent service state under /var/lib.
        #
        # This entry includes:
        # /var/lib/AccountsService  -- GNOME user account metadata (avatars, per-user language overrides).
        # /var/lib/bluetooth        -- Paired Bluetooth device keys.
        # /var/lib/boltd            -- Thunderbolt device authorization database.
        # /var/lib/colord           -- Color calibration profiles and device-to-profile mappings (SQLite DBs).
        # /var/lib/containers       -- Rootful Podman container images and volumes.
        # /var/lib/cups             -- Printer configurations (PPD driver files).
        # /var/lib/docker           -- Docker container images, volumes, and container metadata.
        # /var/lib/fwupd            -- Firmware update history (pending.db) and LVFS metadata cache.
        # /var/lib/geoclue          -- Geolocation cache.
        # /var/lib/gnome-remote-desktop  -- Self-signed TLS/RDP certificates and state.ini.
        # /var/lib/lastlog          -- Login history database (lastlog2.db).
        # /var/lib/libvirt          -- VM disk images, network definitions, VM metadata, per-VM NVRAM, etc.
        # /var/lib/machines         -- systemd-nspawn container/VM images managed by machinectl
        # /var/lib/misc             -- catch-all for daemons (e.g. dnsmasq, dhcpd).
        # /var/lib/NetworkManager   -- NM internal state: secret_key, seen-bssids, connection timestamps.
        # /var/lib/nixos            -- NixOS UID/GID assignment tables; critical to persist.
        # /var/lib/osquery          -- osquery monitoring database.
        # /var/lib/power-profiles-daemon -- Power profile selection and platform action states.
        # /var/lib/private          -- Real backing store for services using DynamicUser=yes and StateDirectory=.
        # /var/lib/sbctl            -- Secure Boot signing keys.
        # /var/lib/systemd/coredump -- Crash dump files for post-mortem debugging across reboots.
        # /var/lib/systemd/timers   -- Last-run timestamps for systemd calendar timers.
        # /var/lib/tpm2-tss         -- TPM2 software-layer key storage (TSS keystore).
        # /var/lib/upower           -- Battery charge/discharge history.
        "/var/lib"

        # Skipped directories (commented out with rationale):

        # `root` is not supposed to be actively used on the machine,
        # and does not have any state that needs to be preserved.
        # ...except ~/.config/sops, which is preserved specifically above.
        # "/root"

        # /var/db: only contains sudo/ lecture tracking.
        # Handled instead in configuration.nix using
        # `security.sudo.extraConfig = "Defaults lecture = never"`
        # "/var/db"

        # /var/spool: only contains the CUPS print queue (active jobs at shutdown).
        # Losing in-flight print jobs at shutdown is acceptable;
        # printer config (PPD files) is preserved via /var/lib/cups above.
        # "/var/spool"
      ];
      files = [
        # Stable machine identity used by systemd, D-Bus, and journalctl.
        # Without this a new ID is generated each boot; journalctl cannot correlate
        # logs across boots and some services derive unstable IDs. Must be in initrd.
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];
    };
  };

  # `systemd-machine-id-commit.service` would fail, but it is not relevant
  # in this specific setup for a persistent `machine-id`, so we disable it.
  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
}
