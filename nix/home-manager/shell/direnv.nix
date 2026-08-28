_: {

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
  };
}
