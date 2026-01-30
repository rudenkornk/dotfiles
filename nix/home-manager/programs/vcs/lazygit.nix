_: {
  programs.lazygit = {
    enable = true;
    # Disable bash integration, since it is broken in lazygit:
    #     bash: ~/.bashrc: line 82: syntax error near unexpected token `('
    #     bash: ~/.bashrc: line 82: `lg() {'
    # https://github.com/nix-community/home-manager/pull/8670
    enableBashIntegration = false;
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
