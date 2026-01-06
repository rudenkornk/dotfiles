{ pkgs, ... }:
{
  programs.gnome-shell = {
    enable = true;

    # Note about tiling extensions.
    # There are quite a few tiling extensions for GNOME Shell, let's list some of them here.
    #
    # Tiling Shell
    # https://extensions.gnome.org/extension/7065/tiling-shell/
    # https://github.com/domferr/tilingshell
    # Windows-like windows snapping. Does not enforce tiling, just adds some neat helpers.
    # Mark: 👎
    #
    # Tactile
    # https://extensions.gnome.org/extension/4548/tactile/
    # https://gitlab.com/lundal/tactile
    # Similar to gTile -- places windows into a *manually specified* place with keyboard shortcuts.
    # Does not enforce tiling.
    # Mark: 👎
    #
    # gTile
    # https://extensions.gnome.org/extension/4442/gsnap/
    # https://github.com/gTile/gTile
    # A simple util, which places windows into a *manually specified* place with mouse or shortcuts.
    # Also does not enforce tiling, but provides a grid to snap windows into.
    # Mark: 👎
    #
    # Tiling Assistant
    # https://extensions.gnome.org/extension/3733/tiling-assistant/
    # https://github.com/Leleat/Tiling-Assistant
    # Does not appear to work out of the box.
    # Anyway looks like it does not enforce tiling either.
    # Mark: 👾
    #
    # ShellTile
    # https://extensions.gnome.org/extension/657/shelltile/
    # https://github.com/emasab/shelltile
    # Looks unmaintained, also displays as "incompatible".
    # Mark: ❌
    #
    # PaperWM
    # https://extensions.gnome.org/extension/6099/paperwm/
    # https://github.com/paperwm/PaperWM
    # Actual tiling WM, works relatively well.
    # A little buggy, shortcuts and gestures does not work as expected.
    # Also lacks some keybinds to manipulate window positions.
    # Mark: 👾
    #
    # pop-shell
    # -
    # https://support.system76.com/articles/pop-keyboard-shortcuts/
    # Actual tiling WM, works great.
    # A bit quirky shortcuts customization.
    # Mark: 👍
    #
    # Forge
    # https://extensions.gnome.org/extension/4481/forge/
    # https://github.com/forge-ext/forge
    # Actual tiling WM, works well.
    # Mark: 👍

    extensions = with pkgs.gnomeExtensions; [
      # See https://github.com/NixOS/nixpkgs/issues/314969 regarding keybinding customization.
      { package = pop-shell; }
      # { package = forge; }
      # { package = paperwm; }
    ];
  };
}
