{
  config,
  pkgs,
  inputs,
  host,
  users,
  ...
}:

{
  imports = [
    host.file
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  boot = {
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

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager = {
      enable = true;
      plugins = with pkgs; [ networkmanager-openvpn ];
    };
  };

  time.timeZone = "Europe/Moscow";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  sops.age.keyFile = "/root/.config/sops/age/keys.txt";
  sops.secrets = { };

  services = {
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };

    desktopManager.gnome = {
      enable = true;
      extraGSettingsOverridePackages = [ pkgs.mutter ];
      extraGSettingsOverrides = ''
        [org.gnome.mutter]
        experimental-features=['scale-monitor-framebuffer']
      '';
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

    printing.enable = true;
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
  };

  # Enable sound with pipewire.
  security = {
    rtkit.enable = true;
    tpm2 = {
      # https://nixos.org/manual/nixos/stable/#module-security-tpm2-nixosmodule
      enable = true;
      abrmd.enable = true;
      pkcs11.enable = true;

      tctiEnvironment.enable = true;
      tctiEnvironment.interface = "tabrmd";
    };
  };

  users.users = builtins.mapAttrs (name: user: {
    isNormalUser = true;
    inherit (user) description;
    extraGroups = [
      "networkmanager"
      "wheel"
      "tss"
    ];
  }) users;

  home-manager = {
    extraSpecialArgs = { inherit pkgs inputs; };
    users = builtins.mapAttrs (
      name: user: args:
      import ./home-manager/home.nix (args // { inherit user; })
    ) users;
  };

  nixpkgs.overlays = [ (import ./home-manager/nixpkgs/overlays/sops-cached.nix) ];

  environment.systemPackages = with pkgs; [
    git
    sbctl
    vim
    wget
  ];

  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Add any missing dynamic libraries for unpackaged programs
        # here, NOT in environment.systemPackages
      ];
    };
    # https://github.com/NixOS/nixpkgs/issues/350383#issuecomment-2435727492
    appimage = {
      enable = true;
      binfmt = true;
      package = pkgs.appimage-run.override {
        # Extra libraries and packages for Appimage run
        extraPkgs =
          pkgs: with pkgs; [
            libepoxy
            brotli
            xdg-user-dirs
          ];
      };
    };
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
