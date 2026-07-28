{
  flake.wrappers.fish.shellAliases = {
    b = "bat";
  };

  flake.modules.homeManager.base = _: {
    programs.bat = {
      enable = true;
    };

    home.shellAliases = {
      b = "bat";
    };

    home.sessionVariables = {
      MANPAGER = "bat --plain --language man";
    };
  };
}
