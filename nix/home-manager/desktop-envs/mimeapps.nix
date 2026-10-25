_:

# Default applications for `xdg-open` and GNOME's "Open With".
{
  xdg.mimeApps.enable = true;

  xdg.mimeApps.defaultApplications =
    let
      browser = "firefox.desktop";
      editor = "org.gnome.TextEditor.desktop";
      video = "vlc.desktop";
      image = "org.gnome.Loupe.desktop";
      audio = "org.gnome.Decibels.desktop";
      pdf = "org.gnome.Papers.desktop";
      archive = "org.gnome.FileRoller.desktop";
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
      "application/x-subrip" = editor;
      "text/tab-separated-values" = editor;
      "text/vtt" = editor;
      "text/markdown" = editor;
      "text/csv" = editor;
      "application/yaml" = editor;
      "application/xml" = editor;
      "application/toml" = editor;
      "application/x-shellscript" = editor;
      "text/x-python" = editor;
      "text/javascript" = editor;
      "text/css" = editor;
      "text/rust" = editor;
      "text/x-go" = editor;
      "text/x-lua" = editor;
      "text/x-csrc" = editor;
      "text/x-chdr" = editor;
      "text/x-c++src" = editor;
      "text/x-c++hdr" = editor;
      "text/x-java" = editor;
      "application/x-ruby" = editor;

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

      "application/pdf" = browser;

      "application/zip" = archive;
      "application/x-7z-compressed" = archive;
      "application/vnd.rar" = archive;
      "application/x-rar" = archive;
      "application/x-rar-compressed" = archive;
      "application/x-tar" = archive;
      "application/x-compressed-tar" = archive;
      "application/x-bzip-compressed-tar" = archive;
      "application/x-xz-compressed-tar" = archive;
      "application/x-zstd-compressed-tar" = archive;
      "application/x-lzma-compressed-tar" = archive;
      "application/x-lzip-compressed-tar" = archive;
      "application/x-tarz" = archive;
      "application/gzip" = archive;
      "application/x-gzip" = archive;
      "application/x-bzip" = archive;
      "application/x-bzip2" = archive;
      "application/x-xz" = archive;
      "application/zstd" = archive;
      "application/x-lzma" = archive;
      "application/x-lzip" = archive;
      "application/x-compress" = archive;
    };
}
