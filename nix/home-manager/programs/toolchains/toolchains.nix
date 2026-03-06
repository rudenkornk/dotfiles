{ pkgs, ... }:

# Compilers, interpreters, build systems & language processors.
{
  home.packages = with pkgs; [
    (lib.hiPrio gcc)
    (lib.setPrio 10 python3)
    (lib.setPrio 11 python311)
    (lib.setPrio 12 python312)
    (lib.setPrio 13 python313)
    (lib.setPrio 14 python314)
    ansible
    automake
    bison
    cargo
    ccache
    clang
    clippy
    cmake
    dart
    dotnet-sdk
    flex
    gleam
    gnumake
    go
    graphviz
    jq
    libgcc
    llvm
    lua5_4
    m4
    mermaid-cli
    molecule
    ninja
    nodejs
    nushell
    ocaml
    openjdk21
    perl
    php
    pkg-config
    poppler-utils
    python3Packages.pylatexenc
    ruby
    rustc
    rustfmt
    tcl
    texlive.combined.scheme-full
    typst
    valgrind
    yq
    zig
  ];
}
