{ pkgs, config, ... }:

{
  home = {
    packages = with pkgs; [ libreoffice ];
  };

}
