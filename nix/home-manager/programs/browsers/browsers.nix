{ pkgs, ... }:

# GUI apps.
{
  home = {
    packages = with pkgs; [ google-chrome ];
  };

  programs = {
    firefox = {
      enable = true;
    };
  };

}
