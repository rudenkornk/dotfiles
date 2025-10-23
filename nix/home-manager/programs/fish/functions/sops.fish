if not string match --quiet "*unshare*vim*" "$SOPS_EDITOR"
    echo '$SOPS_EDITOR variable is configured incorrectly!'
    echo 'Expected to see "unshare" and "vim" in the variable value.'
    echo "SOPS_EDITOR=$SOPS_EDITOR"
    return 1
end
# sops already uses "$SOPS_EDITOR" internally.
# Still, set $EDITOR to $SOPS_EDITOR to avoid any security issues.
set --export --local EDITOR "$SOPS_EDITOR"

command sops $argv
