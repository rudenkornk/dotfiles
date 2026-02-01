_: {
  programs.oh-my-posh = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    configFile = ./oh-my-posh/config.json;
  };
}
