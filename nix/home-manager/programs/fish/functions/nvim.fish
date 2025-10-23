sops --decrypt @proxy@ 2>/dev/null | string replace -r 'export\s*([^=]+)=(.*)' 'set -fx $1 $2' | source || true
sops --decrypt @keys@ 2>/dev/null | string replace -r 'export\s*([^=]+)=(.*)' 'set -fx $1 $2' | source || true

command nvim $argv
