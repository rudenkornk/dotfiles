{ pkgs, ... }:

# Compilers, interpreters, build systems & language processors.
{
  home.packages = with pkgs.unstable; [
    cargo
    clippy
    rustc
    rustfmt
  ];
}
