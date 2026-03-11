{ pkgs, ... }:

# Compilers, interpreters, build systems & language processors.
{
  home.packages = with pkgs; [
    (lib.hiPrio gcc)
    automake
    bison
    ccache
    clang
    cmake
    flex
    gnumake
    libgcc
    llvm
    m4
    ninja
    pkg-config
  ];
}
