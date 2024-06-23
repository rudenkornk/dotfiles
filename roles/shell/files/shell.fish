fish_add_path "$HOME/.local/bin"

# Prevent accidentally closing terminal
bind \cd delete-char

# Set vertical line cursor
# Actually, no, do not set
# This breaks display for interactive fzf, htop and even ssh command
# printf '\033[6 q'
