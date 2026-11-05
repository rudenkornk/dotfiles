{ config, lib, ... }:

{
  home = {
    file = {
      ".config/gtk-3.0/bookmarks".text = lib.replaceStrings [ "@HOME@" ] [ config.home.homeDirectory ] (
        builtins.readFile ./nautilus/bookmarks.in
      );
    };
  };
}
