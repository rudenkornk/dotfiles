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
  "amazon-q-"
  "claude-"
  "copilot-"
  "crush"
  "cursor-"
  "gemini-"
  "github-"
  "grok-"

  # Generic apps.
  "corefonts"
  "google-chrome"
  "packer"
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
