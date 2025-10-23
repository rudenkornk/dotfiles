{ config, pkgs, ... }:

{
  home = {
    username = "rudenkornk";
    homeDirectory = "/home/rudenkornk";

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "25.05"; # Did you read the comment?

    packages = with pkgs; [

      (lib.hiPrio gcc)
      (lib.hiPrio xorg.xvfb)
      acpi
      age
      alsa-lib
      ansible
      ansible-lint
      asciinema
      atuin
      automake
      bat
      bison
      bzip2
      cacert
      carapace
      ccache
      clang
      cmake
      corefonts
      curl
      dbus
      dconf
      dconf-editor
      delta
      docker
      docker-compose
      dos2unix
      dotnet-sdk_8
      drawio
      dua
      dust
      eza
      fd
      file
      flameshot
      flex
      fontconfig
      fzf
      gccStdenv
      gdb
      gh
      git
      gitAndTools.mr
      gitleaks
      glibcLocales
      gnumake
      gnupg
      gnutar
      go
      google-chrome
      gpgme
      graphviz
      gzip
      hexyl
      hiddify-app
      htop-vim
      hyperfine
      iptables
      iputils
      jq
      kitty
      lazygit
      lftp
      libarchive
      libevent
      libevent
      libgcc
      llvm
      lsb-release
      lua54Packages.jsregexp
      lua54Packages.luafilesystem
      lua54Packages.luarocks
      lua54Packages.luasec
      lua5_4
      moreutils
      ncurses
      neovim
      ninja
      nixfmt
      nodejs
      ntp
      nushell
      oh-my-posh
      openjdk21
      openvpn
      p7zip
      patch
      perl
      perlPackages.Appcpanminus
      pkg-config
      pkg-config
      podman
      poppler_utils
      python311
      python311Packages.libtmux
      python311Packages.packaging
      python311Packages.pip
      python311Packages.psutil
      python311Packages.pygments
      python311Packages.pygobject3
      python311Packages.sympy
      python311Packages.virtualenv
      ripgrep
      rsync
      ruby
      rustup
      rustc
      shellcheck
      shfmt
      sops
      stylua
      tcl
      texlive.combined.scheme-full
      uutils-coreutils-noprefix
      tmux
      tree-sitter
      turbovnc
      typos
      tzdata
      unar
      unrar
      unzip
      valgrind
      vcpkg
      vim
      wget
      wiki-tui
      wslu
      xh
      xsel
      xz
      yazi
      zig
      zip
      zls
      zoxide
      fish
      telegram-desktop
      uv

    ];
  };

  # Let home-manager install and manage itself.
  programs.home-manager.enable = true;
  programs.fish.enable = true;

}
