_: {
  programs = {
    bat = {
      enable = true;
    };

    fish = {
      functions = {
        # Upgraded shellAlias, which recognises images.
        b = {
          wraps = "bat";
          body = builtins.readFile ./fish/functions/b.fish;
        };
      };
    };

    zsh = {
      initContent = builtins.readFile ./zsh/functions/b.zsh;
    };

    bash = {
      initExtra = builtins.readFile ./bash/functions/b.sh;
    };

    nushell = {
      extraConfig = builtins.readFile ./nushell/functions/b.nu;
    };

  };

  home.sessionVariables = {
    MANPAGER = "bat --plain --language man";
  };
}
