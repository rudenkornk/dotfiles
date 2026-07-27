{
  flake.modules.homeManager.base = _: {
    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };

    programs.fish = {
      functions = {
        c = {
          wraps = "z";
          body = builtins.readFile ./_fish/functions/c.fish;
        };
      };
    };
  };
}
