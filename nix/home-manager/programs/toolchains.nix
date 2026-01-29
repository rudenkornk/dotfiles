{ pkgs, ... }:

# Compilers, interpreters, debuggers & build systems.
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
    flex
    gdb
    gnumake
    go
    graphviz
    jq
    libgcc
    llvm
    lua5_4
    m4
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
  ];
}
