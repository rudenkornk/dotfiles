# https://carapace-sh.github.io/carapace-bin/setup.html#nushell

$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'

if not (echo "~/.cache/carapace/init.nu" | path exists) {
  mkdir ~/.cache/carapace
  carapace _carapace nushell | save --force ~/.cache/carapace/init.nu
}

source ~/.cache/carapace/init.nu
