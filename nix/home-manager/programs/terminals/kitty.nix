{ pkgs, ... }:

{
  xdg.configFile = {
    "kitty/themes".source = "${pkgs.kitty-themes}/share/kitty-themes/themes";
  };

  home = {
    packages = with pkgs; [
      kitty
      fontconfig
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
    ];
  };
}
