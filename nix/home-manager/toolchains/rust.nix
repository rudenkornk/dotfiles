{ pkgs, ... }:

# Compilers, interpreters, build systems & language processors.
{
  home.packages = with pkgs; [
    cargo
    clippy
    rustc
    rustfmt
  ];
}
