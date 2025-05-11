use std/dirs

$env.config.buffer_editor = "nvim"
$env.config.show_banner = false
$env.config.history.max_size = 1_000_000
$env.config.history.file_format = "sqlite"

def c [argv: string = ""] {
  if $argv == "-" or $argv == "" {
    dirs drop
    eza --all --classify --icons
  } else {
    dirs add .
    z $argv; eza --all --classify --icons
  }
}
source $"($nu.home-path)/.cargo/env.nu"
