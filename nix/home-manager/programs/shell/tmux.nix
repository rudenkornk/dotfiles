{ pkgs, inputs, ... }:

{
  programs.tmux = {
    enable = true;

    # Actually false by default, but let's set it explicitly, to avoid mistakes.
    # newSession has an adverse side effect: a new session is also created on config reload.
    newSession = false;

    # home-manager actually has `sensibleOnTop` option, but for some reason it loads `sensible` at the very top.
    # After that home-manager **overwrites** same settings with its own defaults.
    # That makes resulting tmux.conf hard to read.
    # After some back & forth changes I decided to ditch both `sensibleOnTop` and `sensible` plugin,
    # and just list everything explicitly here.
    escapeTime = 0; # Address vim mode switching delay (http://superuser.com/a/252717/65504).
    historyLimit = 50000; # Scrollback buffer size.
    # Emacs key bindings in tmux command prompt (prefix + :) are better than vi keys, even for vim users.
    keyMode = "emacs";
    focusEvents = true;
    aggressiveResize = true;
    mouse = true;
    baseIndex = 1;
    terminal = "tmux-256color";
    shell = "${pkgs.lib.getExe pkgs.fish}";

    prefix = "C-s";
    extraConfig = builtins.readFile ./tmux/tmux.conf;
    plugins = with pkgs.tmuxPlugins; [
      {
        # Quick copy pane contents with tmux-fingers,
        # Alternatives to tmux-fingers:
        # CrispyConductor/tmux-copy-toolkit: too much key bindings, hard to configure, poor UX, quickcopy mode enables weird highlighting.
        # abhinav/tmux-fastcopy: works great, but flashes screen.
        # fcsonline/tmux-thumbs: flashes screen.
        # tmux-plugins/tmux-copycat: too much key bindings, does not have easy mode.
        # tmux-plugins/tmux-urlview: only urls.
        plugin = fingers;
        extraConfig = # tmux
          ''
            set -g @fingers-key 'C-f'
          '';
      }
      {
        plugin = fzf-tmux-url;
        extraConfig = # tmux
          ''
            set -g @fzf-url-fzf-options '-w 50% -h 50%'
          '';
      }
      {
        plugin = jump;
        extraConfig = # tmux
          ''
            set -g @jump-key 'C-d'
          '';
      }
      {
        plugin = yank;
        extraConfig = # tmux
          ''
            set -g @yank_action 'copy-pipe' # or 'copy-pipe-and-cancel' for the default
          '';
      }
      {
        plugin = pkgs.unstable.tmuxPlugins.ukiyo;
        extraConfig = # tmux
          ''
            set -g @ukiyo-theme 'tokyonight/night'
            set -g pane-border-style fg=#80f0ff,bg=#1a1b26 # bg should be in sync with ukiyo-theme.
            set -g pane-active-border-style fg=#80f0ff,bg=#1a1b26


            set -g @ukiyo-plugins "network-bandwidth disk-usage cpu-usage ram-usage custom:${./tmux/custom.sh} ssh-session"
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
      }
    ];
  };

  programs.fish = {
    interactiveShellInit = builtins.readFile ./tmux/fish/conf.d/tmux.fish;
  };
}
