{
  config,
  pkgs,
  inputs,
  hm_inputs,
  host,
  users,
  ...
}:

{
  imports = [
    host.hardware-configuration
    inputs.home-manager.nixosModules.default
    inputs.preservation.nixosModules.default
    inputs.disko.nixosModules.disko
    ./modules/merge-config/nixos.nix
    ./modules/secrets/nixos.nix
    ./disk.nix
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

  boot = {
    initrd.systemd.enable = true;

    loader = {
      limine = {
        enable = true;
        secureBoot.enable = true;
        style = {
          wallpapers = [ ];
        };
      };
      efi.canTouchEfiVariables = true;
    };

    kernelPackages = pkgs.linuxPackages_latest;
  };

  hardware = {
    bluetooth = {
      enable = true;
    };
    i2c = {
      enable = true;
    };

    firmware = [ pkgs.sof-firmware ];
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  networking = {
    hostName = host.name;
    networkmanager = {
      enable = true;
      # Hand DNS to systemd-resolved (enabled below) so NetworkManager connections
      # get per-link split-DNS.
      dns = "systemd-resolved";
      plugins = with pkgs; [
        networkmanager-openconnect
        networkmanager-openvpn
        networkmanager-ssh
      ];
    };
    # Smart cards and TPM for wifi connections work with hardening enabled,
    # thanks to the token access granted in `systemd.services.wpa_supplicant` below.
    wireless.enableHardening = true;
  };

  systemd.services.wpa_supplicant = {
    environment = {
      # OpenSSL's dynamic engine loader only searches OpenSSL's own store path,
      # which does not contain the `pkcs11` engine (it is built separately, in `libp11`),
      # so `ENGINE_by_id("pkcs11")` fails unless the search path is redirected to `libp11`.
      # Backport of `networking.wireless.pkcs11.enable` pending in nixpkgs
      # (branch `nixos-wireless-pkcs11-engine`).
      # See `./nix/nixpkgs/overlays/libp11.nix` for the whole picture.
      OPENSSL_ENGINES = "${pkgs.lib.getLib pkgs.libp11}/lib/engines";
      # `security.tpm2.tctiEnvironment` exports this variable only to login shells,
      # not to systemd units, so mirror it here for the TPM2 PKCS#11 module.
      inherit (config.environment.variables) TPM2_PKCS11_TCTI;
    };
    # Token access for the hardened service, backport of the same pending nixpkgs branch.
    # The additions merge with the hardening attrset of the upstream wireless module:
    # repeated `BindPaths`/`DeviceAllow` assignments append in systemd.
    # The tabrmd D-Bus policy only admits the tss user and group, which the `SupplementaryGroups`
    # below satisfies: dbus-broker checks the actual peer groups via `SO_PEERGROUPS`.
    serviceConfig = {
      # The token store must be writable by the service: tpm2-pkcs11 refuses to initialize
      # without the advisory lock file it creates next to its sqlite database,
      # and write access also keeps schema migrations and token state updates working.
      # The "+" prefix runs the commands with full privileges outside the sandbox,
      # same as the upstream module's own chown lines, and "-" tolerates hosts without a store.
      # Re-running recursively on every start keeps files created by root-side tools
      # (the lock file, sqlite journals) group-writable as well.
      ExecStartPre = [
        "-+${pkgs.coreutils}/bin/chgrp --recursive wpa_supplicant /etc/tpm2_pkcs11"
        "-+${pkgs.coreutils}/bin/chmod --recursive g+w /etc/tpm2_pkcs11"
      ];
      BindPaths = [
        # Token access for the PKCS#11 backends: the kernel TPM resource manager,
        # the pcscd socket for smartcard readers, and the writable tpm2-pkcs11 token store
        # (nested bind mounts apply in path order, so it overrides the read-only `/etc`).
        # Missing paths are skipped ("-" prefix).
        "-/dev/tpmrm0"
        "-/run/pcscd"
        "-/etc/tpm2_pkcs11"
      ];
      DeviceAllow = [ "/dev/tpmrm0 rw" ];
      # The TPM resource manager device node is owned by the tss group
      # (see the udev rules in the `security.tpm2` module).
      SupplementaryGroups = [ config.security.tpm2.tssGroup ];
    };
  };
  local = {
    secrets = {
      links = {
        "/etc/NetworkManager/system-connections/" = {
          source = pkgs.locallib.secrets + /nmconnections;
          recursive = true;
        };
      };
      before = [ "NetworkManager.service" ];
    };
  };

  time.timeZone = "Europe/Moscow";

  i18n = {
    defaultLocale = "en_GB.UTF-8";
    extraLocales = "all";
    extraLocaleSettings = {
      LC_ADDRESS = "en_GB.UTF-8";
      LC_IDENTIFICATION = "en_GB.UTF-8";
      LC_MEASUREMENT = "en_GB.UTF-8"; # Metric system.
      LC_MONETARY = "en_GB.UTF-8";
      LC_NAME = "en_GB.UTF-8";
      LC_NUMERIC = "en_GB.UTF-8";
      LC_PAPER = "en_GB.UTF-8"; # A4 paper size.
      LC_TELEPHONE = "en_GB.UTF-8";
      LC_TIME = "en_GB.UTF-8"; # 24-hour, DD/MM/YYYY format.
    };
  };

  services = {
    displayManager.gdm = {
      enable = true;
    };

    desktopManager.gnome = {
      enable = true;
    };

    power-profiles-daemon = {
      enable = true;
    };

    upower = {
      enable = true;
    };

    xserver = {
      enable = true;

      xkb = {
        layout = "qwerty_rnk";
        variant = "";
        extraLayouts = {
          qwerty_rnk = {
            description = "English (qwerty, rnk)";
            languages = [ "eng" ];
            symbolsFile = ./keyboard/qwerty_rnk;
          };
          jcuken_rnk = {
            description = "Russian (jcuken, rnk)";
            languages = [ "rus" ];
            symbolsFile = ./keyboard/jcuken_rnk;
          };
        };
      };
    };

    # System DNS resolver, providing per-link split-DNS for VPN connections.
    # Docker ignores the 127.0.0.53 stub in resolv.conf and falls back to public DNS,
    # so containers needing internal names may require explicit `daemon.json` dns.
    resolved = {
      enable = true;
      # Avahi below already answers multicast DNS, and two stacks on one host make `.local` lookups unreliable,
      # which avahi reports as "Detected another IPv4/IPv6 mDNS stack running on this host" at every boot.
      settings.Resolve.MulticastDNS = "no";
    };

    # https://wiki.nixos.org/wiki/Printing
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    printing = {
      enable = true;
      drivers = with pkgs; [
        cups-browsed
        cups-filters
      ];

      # Security issues?
      # https://discourse.nixos.org/t/newly-announced-vulnerabilities-in-cups/52771
      browsed.enable = false;
      browsing = false; # Default value.
      defaultShared = false; # Default value.
      startWhenNeeded = true; # Default value.
    };

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Firmware updates.
    fwupd = {
      enable = true;
    };

    # Fingerprint.
    fprintd = {
      enable = true;
    };

    pcscd = {
      enable = true;
    };
  };

  # Enable sound with pipewire.
  security = {
    rtkit.enable = true;
    pam = {
      services = {
        sudo = {
          # Right now fingerprints on linux is a security theater.
          # Still better than typing a long password every time though.
          fprintAuth = true;
          rules.auth.fprintd.settings.timeout = -1;
        };
      };
    };
    # /var/db/sudo (lecture tracking) is not preserved across reboots in the
    # impermanence setup, so disable the one-time lecture to avoid it printing
    # on every first sudo invocation after boot.
    sudo.extraConfig = "Defaults lecture = never";
    tpm2 = {
      # https://nixos.org/manual/nixos/stable/#module-security-tpm2-nixosmodule
      enable = true;
      abrmd.enable = true;
      pkcs11.enable = true;

      tctiEnvironment.enable = true;
      tctiEnvironment.interface = "tabrmd";
    };
  };

  users = {
    mutableUsers = false;
    users = builtins.mapAttrs (name: user: {
      isNormalUser = true;
      inherit (user) description;

      hashedPassword = pkgs.lib.fileContents (pkgs.locallib.secrets + /hashedPasswordFile);
      extraGroups = [
        "docker"
        "i2c"
        "libvirtd"
        "networkmanager"
        "tss"
        "wheel"
        "wireshark"
      ];
    }) users;
  };

  home-manager = {
    extraSpecialArgs = {
      inputs = hm_inputs;
      inherit pkgs host;
    };
    users = builtins.mapAttrs (name: user: {
      # `home-manager.extraSpecialArgs` is shared across all users,
      # so there is no built-in way to inject per-user data that way.
      # To work around this, we re-export `user` through `_module.args` here,
      # which makes it available as a regular module argument in home-manager modules.
      _module.args.user = user;
      imports = [ ./home-manager/home.nix ];
    }) users;
    backupCommand = "${pkgs.lib.getExe pkgs.trash-cli}";
  };

  environment = {
    systemPackages = with pkgs; [
      # Bare minimal devset.
      git
      vim
      wget

      # Secure boot helpers.
      e2fsprogs
      sbctl

      # WIFI with hardware token support.
      libp11
      tpm2-pkcs11
    ];
    etc = {
      # Register the TPM2 module with p11-kit, so that PKCS#11 consumers going through
      # the p11-kit proxy (the OpenSSL `pkcs11` engine, Firefox, `p11tool`) discover the
      # TPM2 token without per-application module path configuration.
      # Backport of a pending `security.tpm2` change in nixpkgs (branch `nixos-tpm2-p11-kit-module`).
      # See `./nix/nixpkgs/overlays/libp11.nix` for the whole picture.
      "pkcs11/modules/tpm2_pkcs11.module".text = ''
        module: ${pkgs.lib.getLib config.security.tpm2.pkcs11.package}/lib/libtpm2_pkcs11.so
      '';
      # System-wide htop defaults. htop reads `/etc/htoprc` when a user has no
      # `~/.config/htop/htoprc`. Regular users get their own via home-manager,
      # so this covers root and any other config-less account.
      "htoprc".source = ./home-manager/programs/system/configs/.config/htop/htoprc;
    };
  };

  programs = {
    niri.enable = true;

    wireshark = {
      enable = true;
      usbmon.enable = true;
      dumpcap.enable = true;
    };

    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Add any missing dynamic libraries for unpackaged programs
        # here, NOT in `environment.systemPackages`.
      ];
    };
    # https://github.com/NixOS/nixpkgs/issues/350383#issuecomment-2435727492
    appimage = {
      enable = true;
      binfmt = true;
      package = pkgs.appimage-run.override {
        # Extra libraries and packages for `appimage-run`.
        extraPkgs =
          pkgs: with pkgs; [
            libepoxy
            brotli
            xdg-user-dirs
          ];
      };
    };
    virt-manager.enable = true;
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
    docker.enable = true;
    libvirtd.enable = true;
  };

}
