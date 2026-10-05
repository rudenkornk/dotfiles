#!/usr/bin/env bash
sleep "$2"

# Invalidation and reporting share a lock so an expired timer cannot overwrite a newer result.
lock="fish-task-$TMUX_PANE"
tmux wait-for -L "$lock" || exit
if [ "$(tmux show-option -pqv -t "$TMUX_PANE" @fish_task_token)" = "$1" ]; then
  if [ "$(tmux display-message -p -t "$TMUX_PANE" '#{alternate_on}')" = 1 ]; then
    tmux set-option -pu -t "$TMUX_PANE" @fish_task_token
  else
    agent_type="$(tmux show-option -pqv -t "$TMUX_PANE" @agent_type)"
    agent_status="$(tmux show-option -pqv -t "$TMUX_PANE" @agent_status)"
    if [ "$agent_type" = process ] || [ -z "$agent_status" ]; then
      tmux-agent-status set --agent process --state running </dev/null
    fi
  fi
fi
tmux wait-for -U "$lock"
