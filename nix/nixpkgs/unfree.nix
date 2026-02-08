{ lib, ... }:

pkg:
builtins.any (prefix: lib.hasPrefix prefix (lib.getName pkg)) [
  # nvidia-related stuff.
  "cuda-"
  "cuda_"
  "libcu"
  "libnpp"
  "libnvjitlink"
  "nvidia-"

  # Printer drivers.
  "brgenml1lpr"
  "cnijfilter2"
  "hplip"
  "samsung-unified-linux-driver"

  # AI.
  "claude-"
  "copilot-"
  "crush"
  "cursor-"
  "gemini-"
  "github-"

  # Generic apps.
  "corefonts"
  "google-chrome"
  "terraform"
  "unrar"
  "vagrant"
]
