for mode in default insert
    bind --mode $mode \cg lazygit
    bind --mode $mode \cy yazi
end

# Prevent accidentally closing terminal
bind \cd delete-char

# Delete by smaller chunks
bind \cw backward-kill-word

fish_config theme choose "ayu Dark"

# Set vertical line cursor
# Actually, no, do not set
# This breaks display for interactive fzf, htop and even ssh command
# printf '\033[6 q'
