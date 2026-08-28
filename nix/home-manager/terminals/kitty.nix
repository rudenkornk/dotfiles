{ pkgs, ... }:

{
  xdg.configFile = {
    "kitty/themes".source = "${pkgs.kitty-themes}/share/kitty-themes/themes";
    "kitty/kitty.conf".source = ./configs/.config/kitty/kitty.conf;
  };

  home = {
    packages = with pkgs; [
      kitty
      fontconfig
      # TODO: consider removing unstable after 26.11
      # Here it is used for some newly-added glyphs.
      unstable.nerd-fonts.fira-code
      unstable.nerd-fonts.jetbrains-mono
    ];
  };
}
