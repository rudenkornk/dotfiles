# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
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
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Use latest kernel.
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

  # Enable networking
  networking = {
    hostName = "nixos";
    networkmanager = {
      enable = true;
      plugins = with pkgs; [ networkmanager-openvpn ];
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  # Select internationalisation properties.
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

  sops.age.keyFile = "/home/rudenkornk/.config/sops/age/keys.txt";
  sops.secrets = {
    corp_vpn_config = {
      sopsFile = ./secrets/vpn/ya_corp_pc.ovpn.sops;
      format = "binary";
    };
    corp_vpn_auth = {
      sopsFile = ./secrets/vpn/ya_corp_pc.auth.sops;
      format = "binary";
    };
  };

  services = {
    # Enable the GNOME Desktop Environment.
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
      # Enable the X11 windowing system.
      enable = true;

      # Configure keymap in X11
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

    # Enable CUPS to print documents.
    printing.enable = true;
    # Enable sound with pipewire.
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    openvpn.servers = {
      corp = {
        config = "config ${config.sops.secrets.corp_vpn_config.path}";
        authUserPass = "${config.sops.secrets.corp_vpn_auth.path}";
        updateResolvConf = true;
        autoStart = false;
      };
    };
  };

  # Enable sound with pipewire.
  security.rtkit.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    rudenkornk = {
      isNormalUser = true;
      description = "Nikita Rudenko";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
    rudenkornk_corp = {
      isNormalUser = true;
      description = "Nikita Rudenko (corp)";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit pkgs inputs; };
    users = {
      "rudenkornk" = args: import ./home-manager/home.nix (args // { username = "rudenkornk"; });
      "rudenkornk_corp" =
        args: import ./home-manager/home.nix (args // { username = "rudenkornk_corp"; });
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    git
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
