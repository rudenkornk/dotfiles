{ pkgs, ... }:

# Compilers, interpreters, build systems & language processors.
{
  home.packages = with pkgs; [
    dart
    dotnet-sdk
    gleam
    go
    jq
    lean4
    lua5_4
    nodejs
    nushell
    ocaml
    openjdk21
    perl
    php
    protobuf
    ruby
    tcl
    yq
    zig
  ];
}
