# kitty, wrapped with its config and theme baked in (the `themes/` include is
# rewritten to the kitty-themes store path).
{ config, ... }:
let
  flakeCfg = config;
in
{
  flake = {
    wrappers.kitty = { wlib, pkgs, ... }: {
      imports = [ wlib.wrapperModules.kitty ];
      package = pkgs.kitty;
      constructFiles.kittyConfig.content =
        builtins.replaceStrings
          [ "themes/Dracula.conf" ]
          [ "${pkgs.kitty-themes}/share/kitty-themes/themes/Dracula.conf" ]
          (builtins.readFile ./_configs/.config/kitty/kitty.conf);
    };

    modules.homeManager.base = { pkgs, ... }: {
      home = {
        packages = with pkgs; [
          flakeCfg.flake.packages.${pkgs.stdenv.hostPlatform.system}.kitty
          fontconfig
          nerd-fonts.fira-code
          nerd-fonts.jetbrains-mono
        ];
      };
    };
  };
}
