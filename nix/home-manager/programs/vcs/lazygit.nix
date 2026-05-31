_: {
  programs = {
    lazygit = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
      settings = {
        gui = {
          # The number of lines you scroll by when scrolling the main window.
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
            findBaseCommitForFixup = ""; # Conflicts with universal `C-f`.
            openStatusFilter = ""; # Conflicts with universal `C-b`.
          };
        };
      };
    };
    fish.interactiveShellInit =
      # fish
      ''
        for mode in default insert
          bind --mode $mode ctrl-g lazygit
        end
      '';

    bash.initExtra =
      # bash
      ''
        bind -x '"\C-g": "lazygit"'
      '';

    zsh.initContent =
      # zsh
      ''
        # ctrl-g is the abort key in zsh (cancel current operation) and should not be overridden.
      '';

    nushell.extraConfig =
      # nu
      ''
        $env.config.keybindings = ($env.config.keybindings | append {
          name: lazygit
          modifier: control
          keycode: char_g
          mode: [emacs, vi_normal, vi_insert]
          event: { send: ExecuteHostCommand cmd: "lazygit" }
        })
      '';
  };
}
