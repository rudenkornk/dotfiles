_: {
  programs.lazygit = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    settings = {
      gui = {
        # The number of lines you scroll by when scrolling the main window
        scrollHeight = 20;
      };
      keybinding = {
        universal = {
          prevPage = "<c-u>";
          nextPage = "<c-d>";
          scrollUpMain-alt2 = "<c-b>";
          scrollDownMain-alt2 = "<c-f>";
        };
        files = {
          findBaseCommitForFixup = ""; # Conflicts with universal C-f
          openStatusFilter = ""; # Conflicts with universal C-b
        };
      };
    };
  };
}
