{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    themeFile = "Dracula";
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11.0;
    };
    shellIntegration = {
      enableFishIntegration = true;
      enableBashIntegration = true;
    };
    settings = {
      scrollback_lines = 100000;
      cursor_blink_interval = 0;
      cursor_shape = "beam";
      enable_audio_bell = false;
      confirm_os_window_close = 0;
      # https://github.com/kovidgoyal/kitty/issues/1951
      clipboard_control = "write-clipboard write-primary no-append";
      hide_window_decorations = true;
      shell = "${pkgs.fish}/bin/fish";
    };
  };

  home = {
    packages =
      with pkgs;
      [ fontconfig ]
      ++ (with pkgs.nerd-fonts; [
        fira-code
        jetbrains-mono
      ]);
  };
}
