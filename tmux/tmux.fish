fish_add_path "$HOME/.local/tmux/bin"

if status is-interactive
and not set -q TMUX
  not tmux ls &> /dev/null; and exec tmux
  tmux ls | grep --quiet --invert-match "(attached)"; and exec tmux a
end
