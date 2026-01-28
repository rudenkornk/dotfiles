{ lib, ... }:

pkg:
builtins.any (prefix: lib.hasPrefix prefix (lib.getName pkg)) [
  # nvidia-related stuff.
  "nvidia-"
  "cuda-"
  "cuda_"
  "libcu"
  "libnvjitlink"
  "libnpp"

  # AI.
  "claude-"
  "crush"
  "cursor-"
  "github-"
  "gemini-"
  "copilot-"

  # Generic apps.
  "google-chrome"
  "corefonts"
  "terraform"
  "unrar"
]
