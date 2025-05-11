$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'

if not ("~/.cache/carapace/init.nu" | path exists) {
  mkdir ~/.cache/carapace
  carapace _carapace nushell | save --force ~/.cache/carapace/init.nu
}

source ~/.cache/carapace/init.nu
