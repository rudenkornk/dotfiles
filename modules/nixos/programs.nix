{
  flake.modules.nixos.base = { pkgs, ... }: {
    # NOTE: keep all of `environment.systemPackages` in this single file.
    # Splitting the list across feature files would make its order depend on
    # module import order, needlessly perturbing the system-path derivation.
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
        # System-wide htop defaults. htop reads `/etc/htoprc` when a user has no
        # `~/.config/htop/htoprc`. Regular users get their own via home-manager,
        # so this covers root and any other config-less account.
        "htoprc".source = ../system/_configs/.config/htop/htoprc;
      };
    };

    programs = {
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
    };
  };
}
