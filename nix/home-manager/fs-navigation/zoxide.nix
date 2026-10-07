_: {
  programs = {
    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };
    fish = {
      functions = {
        c = {
          wraps = "z";
          body = builtins.readFile ./fish/functions/c.fish;
        };
      };
    };
    zsh = {
      initContent = builtins.readFile ./zsh/functions/c.zsh;
    };
    bash = {
      initExtra = builtins.readFile ./bash/functions/c.sh;
    };
    nushell = {
      extraConfig = builtins.readFile ./nushell/functions/c.nu;
    };
  };
}
