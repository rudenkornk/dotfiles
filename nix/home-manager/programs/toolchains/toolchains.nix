{ pkgs, ... }:

# Compilers, interpreters, build systems & language processors.
{
  home.packages = with pkgs; [
    ansible
    cabal-install
    dart
    dotnet-sdk
    ghc
    gleam
    go
    haskellPackages.fast-tags
    haskellPackages.hoogle
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
