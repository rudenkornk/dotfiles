_: {
  programs.oh-my-posh = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
    configFile = ./oh-my-posh/config.json;
  };
}
