{ pkgs, inputs, ... }:

{
  programs.tmux = {
    enable = true;

    # Actually false by default, but let's set it explicitly, to avoid mistakes.
    # newSession has an adverse side effect: a new session is also created on config reload.
    newSession = false;

    prefix = "C-s";
    mouse = true;
    extraConfig = builtins.readFile ./tmux/tmux.conf;
    plugins =
      let
        # TODO: remove this when tmux-ukiyo is updated in nixpkgs.
        # https://github.com/NixOS/nixpkgs/pull/485092
        ukiyo-upd = pkgs.tmuxPlugins.mkTmuxPlugin {
          pluginName = "ukiyo";
          version = "1.0.0";
          src = inputs.tmux_plugin_ukiyo;
        };
      in
      with pkgs.tmuxPlugins;
      [
        {
          # home-manager actually has `sensibleOnTop` option, but for some reason it loads `sensible`
          # at the very top. After that home-manager **overwrites** same settings with its own defaults.
          # Adding sensible as a normal plugin, since in that case it is placed **after** home-manager's defaults.
          plugin = sensible;
        }
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
          plugin = ukiyo-upd;
          extraConfig = ''
            set -g @ukiyo-theme 'tokyonight/night'

            set -g @ukiyo-plugins "network-bandwidth disk-usage cpu-usage ram-usage weather ssh-session"
            set -g @ukiyo-show-powerline true

            set -g @ukiyo-left-icon "#(date '+%d.%m.%y %R')"

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
