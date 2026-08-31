{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      # Screenshot tools.
      ffmpeg
      gifski
      grim
      imagemagick
      ksnip
      satty
      slurp
      tesseract
      translate-shell
      wl-clipboard
      wl-screenrec
      zbar
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
