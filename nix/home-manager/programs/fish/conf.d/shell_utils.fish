for mode in default insert
    bind --mode $mode \cg lazygit
    bind --mode $mode \cy yazi
end

set --export MANROFFOPT -c
set --export MANPAGER "sh -c 'col -bx | bat -l man -p'"

set --export SOPS_EDITOR unshare --net --map-root-user vim -Z -u DEFAULTS -i NONE -n

# Prevent accidentally closing terminal
bind \cd delete-char

fish_config theme choose "ayu Dark"

# Set vertical line cursor
# Actually, no, do not set
# This breaks display for interactive fzf, htop and even ssh command
# printf '\033[6 q'
