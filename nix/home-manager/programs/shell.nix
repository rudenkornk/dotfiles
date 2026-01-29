{ pkgs, get_modules, ... }:

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

  imports = get_modules ./shell;
}
