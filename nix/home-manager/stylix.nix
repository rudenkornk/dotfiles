{ pkgs, inputs, ... }:

{
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-storm.yaml";
    targets.firefox.enable = false;
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
    };
  };

  # We cannot use `pkgs.locallib.get_modules2` in `imports`, because it will result in
  # infinite recursion error.
  imports = [
    inputs.stylix.homeModules.stylix
  ];
}
