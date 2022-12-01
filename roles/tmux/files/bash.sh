#!/usr/bin/env bash

alias tmux='tmux -2 -u'

if : \
  && command -v tmux &> /dev/null \
  && [ -n "$PS1" ] \
  && [[ ! "$TERM" =~ screen ]] \
  && [[ ! "$TERM" =~ tmux ]] \
  && [ -z "$TMUX" ] \
  ; then
  # Only run tmux if either no servers or none is attached
  ! tmux ls &> /dev/null && exec tmux
  tmux ls | grep --quiet --invert-match "(attached)" && exec tmux a
fi

