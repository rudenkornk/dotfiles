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
    wireless = {
      enableHardening = false; # Allow usage of smart cards and TPM for wifi connections.
      extraConfig = ''
        # Note: this configuration is a no-op due to NetworkManager not passing it to wpa_supplicant.
        # It is only specified here if any future upstream changes fix the problem.
        # See `./nix/overlays/wpa_supplicant.nix` in this repo for details.

        # Hint wpa_supplicant on where to search for hardware-keys providers.
        pkcs11_engine_path=/run/current-system/sw/lib/engines/pkcs11.so
        pkcs11_module_path=/run/current-system/sw/lib/libtpm2_pkcs11.so
      '';
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
      autoSuspend = false;
      enable = true;
    };

    desktopManager.gnome = {
      enable = true;
    };

    logind.settings.Login.HandleLidSwitch = "ignore";

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
        noctalia = {
          fprintAuth = true;
          rules.auth.fprintd.settings.timeout = -1;
          unixAuth = true;
        };
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
      imports = [ ./home.nix ];
    }) users;
    backupCommand = "${pkgs.lib.getExe pkgs.trash-cli}";
  };

  environment = {
    sessionVariables = {
      NOCTALIA_PAM_SERVICE = "noctalia";
    };
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
      # W/A for p11 tool not finding libtpm2.
      "pkcs11/modules/libtpm2-pkcs11".text = ''
        module: /run/current-system/sw/lib/libtpm2_pkcs11.so
        critical: yes
      '';
      # System-wide htop defaults. htop reads `/etc/htoprc` when a user has no
      # `~/.config/htop/htoprc`. Regular users get their own via home-manager,
      # so this covers root and any other config-less account.
      "htoprc".source = ./home-manager/system/configs/.config/htop/htoprc;
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
