{ pkgs, ... }:

# Editors.
{
  home.packages = with pkgs; [ vim ];
  imports = [ ./editors/neovim.nix ];
}
