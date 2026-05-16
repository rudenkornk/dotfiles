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
        # All user home directories: dotfiles, shell history, SSH keys, user data.
        "/home"

        # sops age key used to decrypt secrets at runtime.
        "/root/.config/sops"

        # System-level caches (cups, fwupd, libvirt, etc.).
        # Kept to avoid re-downloads on every boot; safe to drop if disk space is a concern.
        "/var/cache"

        # System logs. Required for `journalctl -b -1` and any cross-boot log analysis.
        "/var/log"

        # User account metadata set via GNOME Settings: avatars, per-user language overrides.
        # Currently empty but preserved so GUI-set preferences survive reboots.
        "/var/lib/AccountsService"

        # Paired Bluetooth device keys. Without this all devices (mice, keyboards, headphones)
        # must be re-paired from scratch on every reboot.
        {
          directory = "/var/lib/bluetooth";
          mode = "0700";
        }

        # Thunderbolt device authorization database.
        # Without this the Dell WD22TB4 dock must be manually re-authorized via GNOME Settings on every reboot
        # (iommu policy requires explicit user action).
        "/var/lib/boltd"

        # Color calibration profiles and device-to-profile mappings (SQLite DBs).
        # Without this display color accuracy reverts to uncalibrated defaults every reboot.
        # Requires explicit ownership: colord runs as its own user and has no StateDirectory= in its unit,
        # so systemd does not chown the directory automatically.
        # Without user/group set here, preservation defaults to root:root and colord cannot write its databases.
        {
          directory = "/var/lib/colord";
          user = "colord";
          group = "colord";
        }

        # Rootful Podman container images and volumes.
        # Currently nearly empty but preserved so containers survive reboots if used.
        "/var/lib/containers"

        # Printer configurations: PPD driver files for all installed printers.
        # Without this all printers must be fully reconfigured after every reboot.
        "/var/lib/cups"

        # Docker container images, volumes, and container metadata.
        # Without this all images must be re-pulled after every reboot.
        {
          directory = "/var/lib/docker";
          mode = "0710";
        }

        # Firmware update history (pending.db) and LVFS metadata cache (~1 MB).
        # Without this the metadata is re-downloaded on every boot; history is lost.
        # Safe to drop; kept to avoid unnecessary network traffic on each boot.
        "/var/lib/fwupd"

        # Geolocation cache used by geoclue. Currently empty;
        # Rebuilt automatically on next use via Mozilla Location Services.
        # Kept for consistency.
        "/var/lib/geoclue"

        # Self-signed TLS/RDP certificates (rdp-tls.crt, rdp-tls.key) and state.ini
        # (RDP/VNC credentials and port settings) for GNOME Remote Desktop.
        # Without this, certificates are regenerated on next service start and RDP/VNC
        # clients show a one-time re-trust prompt due to the changed fingerprint.
        # Requires explicit ownership: no StateDirectory= in its unit, so systemd does not
        # chown the directory automatically; preservation defaults to root:root and the
        # service (running as gnome-remote-desktop) cannot write to it.
        {
          directory = "/var/lib/gnome-remote-desktop";
          user = "gnome-remote-desktop";
          group = "gnome-remote-desktop";
          mode = "0700";
        }

        # Login history database (lastlog2.db) used by the lastlog command and PAM.
        # Without this login audit history is wiped on every reboot.
        "/var/lib/lastlog"

        # VM disk images, network definitions, storage pool configs, and VM metadata.
        # Per-VM NVRAM (UEFI variable stores) lives in /var/lib/libvirt/qemu/nvram/.
        # Without this all virtual machines and their UEFI state must be recreated from scratch.
        "/var/lib/libvirt"

        # systemd-nspawn container/VM images managed by machinectl.
        # Currently empty; preserved so nspawn machines survive reboots if used.
        {
          directory = "/var/lib/machines";
          mode = "0700";
        }

        # Catch-all for daemons (e.g. dnsmasq, dhcpd) that write lease files or other
        # state here. Currently empty on this system; kept as a precaution.
        "/var/lib/misc"

        # NetworkManager internal state: secret_key (used to encrypt credentials),
        # seen-bssids, and connection timestamps. Complements system-connections below.
        # Without this NM regenerates its secret key and loses network timing state.
        "/var/lib/NetworkManager"

        # NixOS UID/GID assignment tables. Critical: without this NixOS may reassign
        # different UIDs/GIDs to system users on rebuild, corrupting ownership of all
        # persisted files. Must be available in initrd.
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }

        # Power profile selection and platform action states (trickle_charge, etc.).
        # Without this trickle_charge resets every reboot, causing the battery to charge
        # to 100% instead of the configured ~80% health limit.
        "/var/lib/power-profiles-daemon"

        # Real backing store for all services using both DynamicUser=yes and StateDirectory=
        # in their units (e.g. colord, fwupd, power-profiles-daemon).
        # Systemd creates /var/lib/private/<service>/ here and exposes it via a symlink at
        # /var/lib/<service> to keep the path transparent to the service itself.
        # mode=0700: critical -- the whole point of this directory is that it is inaccessible
        # to unprivileged users so recycled dynamic UIDs cannot access other services' old state.
        # Preservation defaults to 0755 which would break DynamicUser isolation.
        {
          directory = "/var/lib/private";
          mode = "0700";
        }

        # Secure Boot signing keys managed by sbctl.
        # Without this new kernels cannot be signed.
        # System may become unbootable if Secure Boot is enforced and a kernel update occurs.
        {
          directory = "/var/lib/sbctl";
          mode = "0700";
        }

        # Crash dump files for post-mortem debugging across reboots.
        # Without this coredumps from previous boots are lost before analysis.
        "/var/lib/systemd/coredump"

        # Last-run timestamps for systemd calendar timers (fstrim, fwupd-refresh, etc.).
        # Without this every OnCalendar= timer fires immediately on each boot instead of
        # on its configured weekly/monthly schedule.
        "/var/lib/systemd/timers"

        # TPM2 software-layer key storage (TSS keystore). Currently empty.
        # Required if TPM-bound disk unlock (systemd-cryptenroll) or tpm2-pkcs11 is added.
        # Losing it would break decryption. Kept proactively to avoid future pain.
        "/var/lib/tpm2-tss"

        # Battery charge/discharge history for all UPower-tracked devices (laptop, mice).
        # Without this GNOME battery time-remaining estimates reset and re-accumulate slowly.
        "/var/lib/upower"

        # Saved Wi-Fi and VPN connection profiles (passwords, certificates).
        # Without this all networks must be reconfigured from scratch.
        # Kept alongside /var/lib/NetworkManager which holds NM's internal state.
        "/etc/NetworkManager/system-connections"

        # Skipped directories (commented out with rationale):

        # root is not supposed to be actively used on the machine,
        # and does not have any state that needs to be preserved.
        # ...except ~/.config/sops, which is preserved specifically above.
        # "/root"

        # /var/db: only contains sudo/ lecture tracking.
        # Handled instead in configuration.nix using
        # `security.sudo.extraConfig = "Defaults lecture = never"`
        # "/var/db"

        # /var/lib (monolithic): replaced by the granular per-service entries above.
        # "/var/lib"

        # /var/spool: only contains the CUPS print queue (active jobs at shutdown).
        # Losing in-flight print jobs at shutdown is acceptable;
        # printer config (PPD files) is preserved via /var/lib/cups above.
        # "/var/spool"

        # /var/lib/cni: CNI network plugin state.
        # Empty here; rebuilt dynamically by container runtimes on start even when used.
        # "/var/lib/cni"

        # /var/lib/gdm: stores the gdm user's dconf database
        # (login screen monitor layout via monitors.xml, accessibility settings)
        # and seat0/ runtime socket references.
        # The meaningful state (monitor layout, input/accessibility prefs for the login screen)
        # can be managed declaratively via programs.dconf.profiles.gdm or
        # services.displayManager.gdm.settings.
        # "/var/lib/gdm"

        # /var/lib/portables: systemd Portable Services. Empty; feature not in use.
        # "/var/lib/portables"

        # /var/lib/qemu: contains only two Nix store symlinks
        # (firmware/ pointing to OVMF metadata, vhost-user/ pointing to device descriptors).
        # Both are unconditionally recreated by tmpfiles.d L+ rules on every NixOS activation.
        # Per-VM NVRAM (UEFI variable stores) lives in /var/lib/libvirt/qemu/nvram/,
        # which is covered by /var/lib/libvirt above.
        # "/var/lib/qemu"

        # /var/lib/tpm2-udev-trigger: single hash.txt optimization marker used to skip
        # redundant udevadm trigger calls. Losing it causes a harmless re-trigger on boot.
        # "/var/lib/tpm2-udev-trigger"

        # /var/lib/udisks2: the only real content is mounted-fs-persistent, which tracks
        # active udisks2-managed mounts for stale mount-point cleanup on device removal.
        # "/var/lib/udisks2"
      ];
      files = [
        # Stable machine identity used by systemd, D-Bus, and journalctl.
        # Without this a new ID is generated each boot; journalctl cannot correlate
        # logs across boots and some services derive unstable IDs. Must be in initrd.
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }

        # logrotate last-run timestamps per log file.
        # Without this logrotate treats all logs as never rotated and may rotate
        # them immediately on next run.
        "/var/lib/logrotate.status"

        # Skipped files (commented out with rationale):

        # /etc/ssh/ssh_host_*_key: SSH host keys. Not preserved because this machine
        # is not used as an SSH server; sshd is not running.
        # "/etc/ssh/ssh_host_ed25519_key"
        # "/etc/ssh/ssh_host_ed25519_key.pub"
      ];
    };
  };

  # systemd-machine-id-commit.service would fail, but it is not relevant
  # in this specific setup for a persistent machine-id so we disable it.
  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
}
