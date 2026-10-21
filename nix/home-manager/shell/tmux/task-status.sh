#!/usr/bin/env bash

socket=${TMUX%,*}
socket=${socket%,*}
exec 9>"$socket.task-$TMUX_PANE.lock" || exit
flock -x 9 || exit

# Children must not retain the lock after this worker is interrupted.

action=$1
if [ "$action" = clear ]; then
  tmux set-option -pu -t "$TMUX_PANE" @fish_task_token 9>&-
  if [ "$(
    exec 9>&-
    tmux show-option -pqv -t "$TMUX_PANE" @agent_type
  )" = process ]; then
    tmux-agent-status set --agent process --state clear </dev/null 9>&-
  fi
  exit
fi

[ "$(
  exec 9>&-
  tmux show-option -pqv -t "$TMUX_PANE" @fish_task_token
)" = "$2" ] || exit 0
if [ "$action" = finish ]; then
  tmux set-option -pu -t "$TMUX_PANE" @fish_task_token 9>&-
  state=$3
elif [ "$(
  exec 9>&-
  tmux display-message -p -t "$TMUX_PANE" '#{alternate_on}'
)" = 1 ]; then
  tmux set-option -pu -t "$TMUX_PANE" @fish_task_token 9>&-
  exit
else
  state=running
fi

agent_type="$(
  exec 9>&-
  tmux show-option -pqv -t "$TMUX_PANE" @agent_type
)"
agent_status="$(
  exec 9>&-
  tmux show-option -pqv -t "$TMUX_PANE" @agent_status
)"
if [ "$agent_type" = process ] || [ -z "$agent_status" ]; then
  tmux-agent-status set --agent process --state "$state" </dev/null 9>&-
fi
