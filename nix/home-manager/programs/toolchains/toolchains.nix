{ pkgs, ... }:

# Compilers, interpreters, build systems & language processors.
{
  home.packages = with pkgs; [
    (lib.hiPrio gcc)
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
    python311
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
