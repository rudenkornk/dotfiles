{ pkgs, ... }:

# Compilers, interpreters, build systems & language processors.
{
  home.packages = with pkgs; [
    ansible
    dart
    dotnet-sdk
    gleam
    go
    jq
    lean4
    lua5_4
    molecule
    nodejs
    nushell
    ocaml
    openjdk21
    perl
    php
    ruby
    tcl
    terraform
    yq
    zig
  ];
}
