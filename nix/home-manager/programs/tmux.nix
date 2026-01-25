{ pkgs, inputs, ... }:

{
  programs.tmux = {
    enable = true;
    sensibleOnTop = true;
    # Despite enabled sensibleOnTop, home-manager still overrides some of its settings.
    # We need to explicitly set them here again.
    escapeTime = 0;
    historyLimit = 100000;
    terminal = "screen-256color";
    keyMode = "emacs";
    focusEvents = true;
    aggressiveResize = true;

    # Actually false by default, but let's set it explicitly,
    # to avoid mistakes.
    # newSession has an adverse side effect: a new sessions is also created on config reload.
    newSession = false;
    clock24 = true; # No effect actually, since clock is managed by tmux-kanagawa plugin.

    prefix = "C-s";
    mouse = true;
    extraConfig = builtins.readFile ./tmux/tmux.conf;
    plugins =
      let
        # TODO: remove this when tmux-kanagawa is updated in nixpkgs.
        # https://github.com/NixOS/nixpkgs/pull/474114
        kanagawa-upd = pkgs.tmuxPlugins.mkTmuxPlugin {
          pluginName = "kanagawa";
          version = "1.0.0";
          src = inputs.tmux_plugin_kanagawa;
        };
      in
      with pkgs.tmuxPlugins;
      [
        {
          # Quick copy pane contents with tmux-fingers,
          # Alternatives to tmux-fingers:
          # CrispyConductor/tmux-copy-toolkit: too much key bindings, hard to configure, poor UX, quickcopy mode enables weird highlighting.
          # abhinav/tmux-fastcopy: works great, but flashes screen.
          # fcsonline/tmux-thumbs: flashes screen.
          # tmux-plugins/tmux-copycat: too much key bindings, does not have easy mode.
          # tmux-plugins/tmux-urlview: only urls.
          plugin = fingers;
          extraConfig = ''
            set -g @fingers-key 'C-f'
          '';
        }
        {
          plugin = fzf-tmux-url;
          extraConfig = ''
            set -g @fzf-url-fzf-options '-w 50% -h 50%'
          '';
        }
        {
          plugin = jump;
          extraConfig = ''
            set -g @jump-key 'C-d'
          '';
        }
        {
          plugin = yank;
          extraConfig = ''
            set -g @yank_action 'copy-pipe' # or 'copy-pipe-and-cancel' for the default
          '';
        }
        {
          plugin = kanagawa-upd;
          extraConfig = ''
            set -g @kanagawa-theme 'dragon'
            set -g @kanagawa-plugins "network-bandwidth disk-usage cpu-usage ram-usage weather ssh-session"
            set -g @kanagawa-show-powerline true
            set -g @kanagawa-show-edge-icons true

            set -g @kanagawa-network-bandwidth-download-label " "
            set -g @kanagawa-network-bandwidth-upload-label " "
            set -g @kanagawa-cpu-usage-label " "
            set -g @kanagawa-cpu-usage-colors "carp_yellow dark_gray"
            set -g @kanagawa-ram-usage-label " "
            set -g @kanagawa-ram-usage-colors "carp_yellow dark_gray"
            set -g @kanagawa-disk-usage-colors "orange dark_gray"
            set -g @kanagawa-show-location false
            set -g @kanagawa-left-icon "#(date '+%d.%m.%y %R')"
            set -g @kanagawa-show-ssh-session-port true
            set -g @kanagawa-time-colors "green dark_gray"
            set -g @kanagawa-weather-colors "green dark_gray"
          '';
        }
      ];
  };
}
