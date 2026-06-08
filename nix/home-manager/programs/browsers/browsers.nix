{ pkgs, ... }:

# GUI apps.
{
  home = {
    packages = with pkgs; [ google-chrome ];
  };

  programs = {
    chromium = {
      enable = true;
    };
    firefox = {
      enable = true;
    };
    # `about:config` manual changes:
    # `ui.key.menuAccessKeyFocuses = false` to disable the Alt key from focusing the menu bar.
    # `about:keyboard` manual changes:
    # -- Remove ctrl-n keybinding for opening a new window.
  };

}
