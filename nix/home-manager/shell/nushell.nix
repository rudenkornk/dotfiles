{ pkgs, lib, ... }:

{
  programs.nushell = {
    enable = true;
    settings.show_banner = false;
    extraConfig = # nu
      ''
        $env.config.keybindings ++= [
          {
            name: delete_char
            modifier: control
            keycode: char_d
            mode: [emacs vi_insert vi_normal]
            event: {edit: Delete}
          }
          {
            name: backspace_word
            modifier: control
            keycode: char_w
            mode: [emacs vi_insert vi_normal]
            event: {edit: BackspaceWord}
          }
        ]
      '';
  };
}
