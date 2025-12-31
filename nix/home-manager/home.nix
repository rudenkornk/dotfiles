{
  config,
  pkgs,
  inputs,
  username,
  ...
}:

{
  home = {
    inherit username;
    homeDirectory = "/home/${username}";

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "25.11"; # Did you read the comment?

    packages = with pkgs; [
      (pkgs.lib.hiPrio gcc)
      (pkgs.lib.hiPrio xorg.xvfb)
      acpi
      age
      alsa-lib
      angular-language-server
      ansible
      ansible-lint
      asciinema
      astro-language-server
      automake
      bash-completion
      bat
      bison
      bzip2
      cacert
      carapace
      ccache
      clang
      cmake
      coder
      corefonts
      curl
      dbus
      dconf
      dconf-editor
      dconf2nix
      delta
      docker
      docker-compose
      dos2unix
      dotnet-sdk_8
      drawio
      dua
      dust
      fd
      file
      flex
      fontconfig
      fzf
      gdb
      git
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
      statix
      hexyl
      htop-vim
      hyperfine
      iptables
      iputils
      jq
      kubectl
      lftp
      libarchive
      libevent
      libgcc
      llvm
      lsb-release
      lua5_4
      minikube
      moreutils
      ncurses
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      ninja
      nixfmt
      nodejs
      ntp
      nushell
      oh-my-posh
      openjdk21
      openldap
      openvpn
      p7zip
      patch
      perl
      pkg-config
      podman
      poppler-utils
      powershell
      prettier
      python311
      python3Packages.debugpy
      ripgrep
      rsync
      ruby
      rustc
      rustup
      shellcheck
      shfmt
      sops
      stylua
      svelte-language-server
      tcl
      telegram-desktop
      texlive.combined.scheme-full
      tree-sitter
      turbovnc
      typos
      tzdata
      unar
      unrar
      unzip
      uutils-coreutils-noprefix
      uv
      valgrind
      vcpkg
      vim
      virtualbox
      vscode-js-debug
      vue-language-server
      wget
      wiki-tui
      xh
      xsel
      xz
      yarn
      zig
      zip
      zls
    ];

    file = {
      ".config" = {
        source = ./configs/.config;
        recursive = true;
      };
      ".groovylintrc.json".source = ./configs/.groovylintrc.json;
      ".isort.cfg".source = ./configs/.isort.cfg;
      ".markdownlint.yaml".source = ./configs/.markdownlint.yaml;
      ".pydocstyle".source = ./configs/.pydocstyle;

      ".ssh" = {
        source = ./secrets/ssh;
        recursive = true;
      };

      # Workaround for missing mason packages in neovim.
      # https://github.com/LazyVim/LazyVim/discussions/6892
      ".local/share/nvim/mason/packages/angular-language-server/node_modules/@angular/language-server".source =
        "${pkgs.angular-language-server}/lib";
      ".local/share/nvim/mason/packages/astro-language-server/node_modules/@astrojs/ts-plugin".source =
        "${pkgs.astro-language-server}/lib/astro-language-server/packages/ts-plugin/";
      ".local/share/nvim/mason/packages/svelte-language-server/node_modules/typescript-svelte-plugin".source =
        "${pkgs.svelte-language-server}/lib/node_modules/svelte-language-server/packages/typescript-plugin/";
      ".local/share/nvim/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js".source =
        "${pkgs.vscode-js-debug}/lib/node_modules/js-debug/src/dapDebugServer.ts";
      ".local/share/nvim/mason/packages/vue-language-server/node_modules/@vue/language-server".source =
        "${pkgs.vue-language-server}/lib/language-tools/packages/language-server";
    };
  };

  fonts.fontconfig.enable = true;

  imports = [
    ./programs/atuin.nix
    ./programs/docker-cli.nix
    ./programs/eza.nix
    ./programs/fish.nix
    ./programs/git.nix
    ./programs/kitty.nix
    ./programs/lazygit.nix
    ./programs/mypy.nix
    ./programs/neovim.nix
    ./programs/oh-my-posh.nix
    ./programs/ruff.nix
    ./programs/tmux.nix
    ./programs/yazi.nix
    ./programs/zoxide.nix
    ./services/flameshot.nix
    ./dconf/settings.nix
  ];
}
