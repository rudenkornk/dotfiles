{ pkgs, ... }:

# VCS.
{
  imports = [
    ./vcs/git.nix
    ./vcs/lazygit.nix
  ];
}
