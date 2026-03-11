{ pkgs, ... }:

# Libraries typically needed for neovim LSP to work correctly.
{
  home.packages = with pkgs; [
    boost
    fmt
  ];
}
