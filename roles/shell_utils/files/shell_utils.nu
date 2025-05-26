# https://carapace-sh.github.io/carapace-bin/setup.html#nushell

$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'


const config = "~/.config/nushell/autoload"

const carapace = $"($config)/carapace.nu"
if not (echo $carapace | path exists) and not (which carapace | is-empty) {
  carapace _carapace nushell | save $carapace
  #source $carapace
}

const zoxide = $"($config)/zoxide.nu"
if not (echo $zoxide | path exists) and not (which zoxide | is-empty) {
  zoxide init nushell | save -f $zoxide
  #source $zoxide
}

const zoxide = $"($config)/zoxide.nu"
if not (echo $zoxide | path exists) and not (which zoxide | is-empty) {
  zoxide init nushell | save -f $zoxide
  #source $zoxide
}

const ohmyposh = $"($config)/oh-my-posh.nu"
if not (echo $ohmyposh | path exists) and not (which oh-my-posh  | is-empty) {
  oh-my-posh init nu --config ~/.config/oh-my-posh/theme.json --print | save -f $ohmyposh
  #source $ohmyposh
}
