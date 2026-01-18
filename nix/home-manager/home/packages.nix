{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      # Basic tools.
      curl
      git
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
      cargo
      ccache
      clang
      clippy
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
      rustfmt
      tcl
      texlive.combined.scheme-full
      typst
      valgrind
      zig

      # Package managers.
      uv
      vcpkg
      yarn

      # Formatters & linters.
      ansible-lint
      gitleaks
      markdownlint-cli2
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
      age-plugin-tpm
      cacert
      gnupg
      gpgme
      sops
      tpm2-tools

      # Networking tools.
      iptables
      iputils
      lftp
      ntp

      # Remote desktop, corporate tooling & VPNs.
      coder
      openldap
      openvpn
      throne

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
      nix-melt
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

      # CJK fonts for chinese, japanese, korean languages in Chrome.
      wqy_zenhei
      noto-fonts-cjk-sans

      # Monitoring & system info.
      htop-vim
      lsb-release
      lsof
      neofetch
      nvtopPackages.full

      # GUI apps.
      google-chrome
      libreoffice
      telegram-desktop

      # Other useful tools.
      asciinema
      dbus
      dconf
      dconf-editor
      dos2unix
      gh
      hyperfine
      tldr
      wiki-tui
      xh
    ];
  };
}
