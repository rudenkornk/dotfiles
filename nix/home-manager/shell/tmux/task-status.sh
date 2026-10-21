#!/usr/bin/env bash

lock="fish-task-$TMUX_PANE"
tmux wait-for -L "$lock" || exit
trap 'tmux wait-for -U "$lock"' EXIT

action=$1
if [ "$action" = clear ]; then
  tmux set-option -pu -t "$TMUX_PANE" @fish_task_token
  if [ "$(tmux show-option -pqv -t "$TMUX_PANE" @agent_type)" = process ]; then
    tmux-agent-status set --agent process --state clear </dev/null
  fi
  exit
fi

[ "$(tmux show-option -pqv -t "$TMUX_PANE" @fish_task_token)" = "$2" ] || exit 0
if [ "$action" = finish ]; then
  tmux set-option -pu -t "$TMUX_PANE" @fish_task_token
  state=$3
elif [ "$(tmux display-message -p -t "$TMUX_PANE" '#{alternate_on}')" = 1 ]; then
  tmux set-option -pu -t "$TMUX_PANE" @fish_task_token
  exit
else
  state=running
fi

agent_type="$(tmux show-option -pqv -t "$TMUX_PANE" @agent_type)"
agent_status="$(tmux show-option -pqv -t "$TMUX_PANE" @agent_status)"
if [ "$agent_type" = process ] || [ -z "$agent_status" ]; then
  tmux-agent-status set --agent process --state "$state" </dev/null
fi
