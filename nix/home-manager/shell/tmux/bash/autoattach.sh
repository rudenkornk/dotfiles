# shellcheck shell=bash

[[ $- == *i* && ! -v TMUX ]] || return
tmux ls &>/dev/null || exec tmux -2 -u
tmux ls | grep --quiet --invert-match '(attached)' && exec tmux -2 -u a
