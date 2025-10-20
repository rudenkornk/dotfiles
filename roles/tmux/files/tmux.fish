if status is-interactive
    and not set -q TMUX
    not tmux ls &>/dev/null; and exec tmux -2 -u
    tmux ls | grep --quiet --invert-match "(attached)"; and exec tmux -2 -u a
end
