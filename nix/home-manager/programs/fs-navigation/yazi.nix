_: {
  programs = {
    yazi = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
      settings = {
        mgr = {
          show_hidden = true;
        };
      };
      keymap = {
        mgr.prepend_keymap = [
          {
            on = [ "?" ];
            run = "help";
            desc = "Show help";
          }
          {
            on = [ "<C-n>" ];
            run = "arrow 1";
            desc = "Next item";
          }
          {
            on = [ "<C-p>" ];
            run = "arrow -1";
            desc = "Prev item";
          }
          {
            on = [ "<C-d>" ];
            run = "arrow 20";
            desc = "Scroll file list down";
          }
          {
            on = [ "<C-u>" ];
            run = "arrow -20";
            desc = "Scroll file list up";
          }
          {
            on = [ "<C-f>" ];
            run = "seek 10";
            desc = "Scroll content down";
          }
          {
            on = [ "<C-b>" ];
            run = "seek -10";
            desc = "Scroll content up";
          }
        ];
      };
    };
    fish.interactiveShellInit =
      # fish
      ''
        for mode in default insert
          bind --mode $mode ctrl-y yazi
        end
      '';

    bash.initExtra =
      # bash
      ''
        bind -x '"\C-y": "yazi"'
      '';

    zsh.initContent =
      # zsh
      ''
        function _yazi_widget() { yazi; zle reset-prompt }
        zle -N _yazi_widget
        bindkey '^y' _yazi_widget
      '';

    nushell.extraConfig =
      # nu
      ''
        $env.config.keybindings = ($env.config.keybindings | append {
          name: yazi
          modifier: control
          keycode: char_y
          mode: [emacs, vi_normal, vi_insert]
          event: { send: ExecuteHostCommand cmd: "yazi" }
        })
      '';
  };
}
