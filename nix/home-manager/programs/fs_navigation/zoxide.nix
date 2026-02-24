_: {
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
  };

  programs.fish = {
    functions = {
      c = {
        wraps = "z";
        body = builtins.readFile ./fish/functions/c.fish;
      };
    };
  };
}
