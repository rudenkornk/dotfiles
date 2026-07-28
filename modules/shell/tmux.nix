# tmux, wrapped with its full configuration and plugins baked in.
{ config, ... }:
let
  flakeCfg = config;
in
{
  flake = {
    wrappers.tmux = { wlib, pkgs, ... }: {
      imports = [ wlib.wrapperModules.tmux ];
      package = pkgs.tmux;

      # `home-manager` had a `sensibleOnTop` option, but for some reason it loads `sensible` at the very top.
      # After that `home-manager` **overwrites** same settings with its own defaults.
      # That makes resulting tmux.conf hard to read.
      # After some back & forth changes I decided to ditch both `sensibleOnTop` and `sensible` plugin,
      # and just list everything explicitly here.
      sourceSensible = false;

      escapeTime = 0; # Address vim mode switching delay (http://superuser.com/a/252717/65504).
      historyLimit = 50000; # Scrollback buffer size.
      # Emacs key bindings in tmux command prompt (prefix + :) are better than vi keys, even for vim users.
      modeKeys = "emacs";
      statusKeys = "emacs";
      aggressiveResize = true;
      mouse = true;
      baseIndex = 1;
      terminal = "tmux-256color";
      shell = "${pkgs.lib.getExe flakeCfg.flake.packages.${pkgs.stdenv.hostPlatform.system}.fish}";
      prefix = "C-s";

      # Defaults of the wrapper module which would deviate from the previous
      # home-manager-generated tmux.conf; keep the old behavior.
      clock24 = false;
      disableConfirmationPrompt = false;
      allowPassthrough = false;
      updateEnvironment = [ ];

      # Plugin settings are global `@`-options and may all be set before the
      # plugins are sourced.
      configBefore = ''
        set -g focus-events on

        # Quick copy pane contents with tmux-fingers.
        # Alternatives to tmux-fingers:
        # CrispyConductor/tmux-copy-toolkit: too much key bindings, hard to configure, poor UX,
        # quickcopy mode enables weird highlighting.
        # abhinav/tmux-fastcopy: works great, but flashes screen.
        # fcsonline/tmux-thumbs: flashes screen.
        # tmux-plugins/tmux-copycat: too much key bindings, does not have easy mode.
        # tmux-plugins/tmux-urlview: only urls.
        set -g @fingers-key 'C-f'


        set -g @fzf-url-fzf-options '-w 50% -h 50%'


        set -g @jump-key 'C-d'


        set -g @yank_action 'copy-pipe' # Or 'copy-pipe-and-cancel' for the default.


        set -g @ukiyo-theme 'tokyonight/night'
        set -g pane-border-style fg=#80f0ff,bg=#1a1b26 # bg should be in sync with ukiyo-theme.
        set -g pane-active-border-style fg=#80f0ff,bg=#1a1b26


        set -g @ukiyo-plugins "network-bandwidth cpu-usage ram-usage custom:${./_tmux/custom.sh} ssh-session"
        set -g @ukiyo-show-powerline true

        set -g @ukiyo-left-icon "#(date '+%d.%m.%y %R (%a)')"

        set -g @ukiyo-custom-plugin-colors "info bg_pane"

        set -g @ukiyo-network-bandwidth-download-label " "
        set -g @ukiyo-network-bandwidth-upload-label " "
        set -g @ukiyo-network-bandwidth-interval "5"
        set -g @ukiyo-network-bandwidth-min-unit-divisor "1048576"
        set -g @ukiyo-network-bandwidth-unit-fmt "%5.1f"

        set -g @ukiyo-disk-format "%5.1fMiB/s"

        set -g @ukiyo-cpu-usage-label " "
        set -g @ukiyo-cpu-usage-colors "info bg_pane"

        set -g @ukiyo-ram-usage-label " "

        set -g @ukiyo-weather-colors "accent bg_pane"
        set -g @ukiyo-show-location false
        set -g @ukiyo-show-ssh-session-port true
      '';
      plugins = with pkgs.tmuxPlugins; [
        fingers
        fzf-tmux-url
        jump
        yank
        ukiyo
      ];
      configAfter = builtins.readFile ./_tmux/tmux.conf;
    };

    wrappers.fish =
      { pkgs, ... }:
      let
        fishlib = import ./_fish/lib.nix;
      in
      {
        plugins = [
          (fishlib.mkSnippet pkgs "70-tmux-attach" (builtins.readFile ./_tmux/fish/conf.d/tmux.fish))
        ];
      };

    modules.homeManager.base = { pkgs, ... }: {
      home.packages = [ flakeCfg.flake.packages.${pkgs.stdenv.hostPlatform.system}.tmux ];

      xdg = {
        configFile = {
          "tmux/toggle_pane.py".source = ./_tmux/toggle_pane.py;
        };
      };

    };
  };
}
