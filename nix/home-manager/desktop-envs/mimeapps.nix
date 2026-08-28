_:

# Default applications for `xdg-open` and GNOME's "Open With".
{
  xdg.mimeApps.enable = true;

  xdg.mimeApps.defaultApplications =
    let
      browser = "firefox.desktop";
      editor = "nvim.desktop";
      video = "org.gnome.Showtime.desktop";
      image = "org.gnome.Loupe.desktop";
      audio = "org.gnome.Decibels.desktop";
      pdf = "org.gnome.Papers.desktop";
    in
    {
      "text/html" = browser;
      "application/xhtml+xml" = browser;
      "x-scheme-handler/http" = browser;
      "x-scheme-handler/https" = browser;
      "x-scheme-handler/about" = browser;
      "x-scheme-handler/unknown" = browser;

      "text/plain" = editor;
      "application/json" = editor;

      "video/mp4" = video;
      "video/x-matroska" = video;
      "video/webm" = video;
      "video/quicktime" = video;
      "video/x-msvideo" = video;
      "video/mpeg" = video;
      "video/ogg" = video;
      "video/3gpp" = video;
      "video/x-flv" = video;
      "video/x-ms-wmv" = video;

      "audio/mpeg" = audio;
      "audio/flac" = audio;
      "audio/mp4" = audio;
      "audio/x-wav" = audio;
      "audio/vnd.wave" = audio;
      "audio/webm" = audio;
      "audio/ogg" = audio;
      "audio/aac" = audio;

      "image/jpeg" = image;
      "image/png" = image;
      "image/gif" = image;
      "image/webp" = image;
      "image/svg+xml" = image;
      "image/tiff" = image;
      "image/bmp" = image;
      "image/avif" = image;

      "application/pdf" = pdf;
    };
}
