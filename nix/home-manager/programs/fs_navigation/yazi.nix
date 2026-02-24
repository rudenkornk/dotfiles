_: {
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
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
}
