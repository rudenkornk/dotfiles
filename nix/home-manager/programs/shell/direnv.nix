_: {

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
  };

  xdg.configFile."direnv/direnv.toml".source = ./configs/.config/direnv/direnv.toml;
}
