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

  # Vim plugins.
  # Despite "unfree" status in nixpkgs, most of them just do not have any license due to low maintenance.
  # nixpkgs is formally correct in classifying them as unfree though.
  "cmp-emoji"
  "jupytext.nvim"
  "litee.nvim"
  "neotest-dart"
  "NotebookNavigator.nvim"
  "nvim-ansible"
]
