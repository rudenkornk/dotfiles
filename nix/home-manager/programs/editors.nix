{ pkgs, get_modules, ... }:

# Editors.
{
  home.packages = with pkgs; [ vim ];
  imports = get_modules ./editors;
}
