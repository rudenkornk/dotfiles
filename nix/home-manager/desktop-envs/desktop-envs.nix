{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      # Screenshot tools.
      bc
      ffmpeg
      gifski
      grim
      hyprpicker
      imagemagick
      ksnip
      mpv
      satty
      slurp
      tesseract
      translate-shell
      wl-clipboard
      wl-screenrec
      zbar

      # Wallpapers.
      mpvpaper
    ];

    pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Amber";
      size = 32;
    };
  };

  gtk = {
    enable = true;
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Amber"; # Keep in sync with home.pointerCursor.name.
    };
  };

  local = {
    home.file = {
      ".".source = ./configs;
    };
  };
}
