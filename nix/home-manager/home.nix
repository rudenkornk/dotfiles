{
  config,
  pkgs,
  inputs,
  user,
  ...
}:

{
  home = {
    inherit (user) username;
    homeDirectory = "/home/${user.username}";
    sessionVariables = {
      USERKIND = user.userkind;
    };

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "25.11"; # Did you read the comment?

    packages = with pkgs; [
      # Basic tools.
      curl
      git
      htop-vim
      lsb-release
      lsof
      moreutils
      patch
      uutils-coreutils-noprefix
      vim
      wget

      # Compilers, interpreters, debuggers & build systems.
      (pkgs.lib.hiPrio gcc)
      ansible
      automake
      bison
      ccache
      clang
      cmake
      flex
      gdb
      gnumake
      go
      graphviz
      jq
      libgcc
      llvm
      lua5_4
      ninja
      nodejs
      ocaml
      openjdk21
      perl
      pkg-config
      poppler-utils
      python311
      ruby
      rustc
      rustup
      tcl
      texlive.combined.scheme-full
      valgrind
      zig

      # Package managers.
      uv
      vcpkg
      yarn

      # Formatters & linters.
      ansible-lint
      gitleaks
      mypy
      nixfmt
      prettier
      ruff
      shellcheck
      shfmt
      statix
      stylua
      typos

      # Trust & encryption tools.
      age
      cacert
      gnupg
      gpgme
      sops

      # Networking tools.
      iptables
      iputils
      lftp
      ntp

      # Remote desktop, corporate tooling & VPNs.
      coder
      openldap
      openvpn
      turbovnc

      # Virtualization & containerization tools.
      docker
      docker-compose
      kubectl
      minikube
      podman
      virtualbox

      # File management & search tools.
      bat
      dua
      dust
      eza
      fd
      file
      fzf
      hexyl
      ripgrep
      rsync

      # Archival tools.
      bzip2
      gnutar
      gzip
      libarchive
      p7zip
      unar
      unrar
      unzip
      xz
      zip

      # Shells & shells extensions.
      atuin
      bash-completion
      carapace
      fish
      nushell
      oh-my-posh
      powershell
      tmux

      # Nix.
      dconf2nix
      home-manager
      nix-diff
      nix-index
      nix-output-monitor
      nix-top
      nix-tree

      # CLI AI tools.
      aider-chat-full
      claude-code
      codex
      crush
      cursor-cli
      gemini-cli
      github-copilot-cli
      opencode
      qwen-code

      # Fonts & graphics.
      (pkgs.lib.hiPrio xorg.xvfb)
      corefonts
      fontconfig
      ncurses

      # GUI apps.
      google-chrome
      telegram-desktop

      # Other useful tools.
      asciinema
      dbus
      dconf
      dconf-editor
      dos2unix
      gh
      hyperfine
      wiki-tui
      xh
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
    };
  };

  fonts.fontconfig.enable = true;

  imports = [
    ./dconf/settings.nix
    ./programs/atuin.nix
    ./programs/docker-cli.nix
    ./programs/eza.nix
    ./programs/fish.nix
    ./programs/git.nix
    ./programs/kitty.nix
    ./programs/lazygit.nix
    ./programs/mypy.nix
    ./programs/neovim.nix
    ./programs/nix-search-tv.nix
    ./programs/oh-my-posh.nix
    ./programs/ruff.nix
    ./programs/tmux.nix
    ./programs/yazi.nix
    ./programs/zoxide.nix
    ./services/flameshot.nix
  ];
}
