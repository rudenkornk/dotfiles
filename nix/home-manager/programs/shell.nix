{ pkgs, ... }:

# Shells & shells extensions.
{
  home.packages = with pkgs; [
    atuin
    bash-completion
    carapace
    fish
    nushell
    oh-my-posh
    powershell
    tmux
  ];

  imports = [
    ./shell/atuin.nix
    ./shell/bash.nix
    ./shell/fish.nix
    ./shell/oh-my-posh.nix
    ./shell/tmux.nix
  ];
}
