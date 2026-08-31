{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [ telegram-desktop ];
  };

  local = {
    home.file = {
      ".".source = ./configs;
    };
  };
}
