{
  flake.modules.homeManager.base = _: {
    programs.oh-my-posh = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
      configFile = ./_oh-my-posh/config.json;
    };
  };
}
