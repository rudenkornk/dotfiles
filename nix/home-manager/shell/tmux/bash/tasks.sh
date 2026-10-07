# shellcheck shell=bash

[[ $- == *i* && -n ${TMUX-} && -n ${TMUX_PANE-} ]] || return
[[ $(tmux display-message -p -t "$TMUX_PANE" '#{pane_pid}') == "$$" ]] || return
[[ -z ${__tmux_task_initialized-} ]] || return
__tmux_task_initialized=1

tmux_task_min_duration_ms=${tmux_task_min_duration_ms:-10000}
__tmux_task_root=$(dirname -- "${BASH_SOURCE[0]}")/..
tmux_task_exclude=${tmux_task_exclude:-$(tr -d '\n' <"$__tmux_task_root/task-exclude.regex")}
__tmux_task_timer="$__tmux_task_root/task-timer.sh"
__tmux_task_lock="fish-task-$TMUX_PANE"
__tmux_task_generation=0

__tmux_task_clear() (
  tmux wait-for -L "$__tmux_task_lock" || return
  trap 'tmux wait-for -U "$__tmux_task_lock"' EXIT
  tmux set-option -pu -t "$TMUX_PANE" @fish_task_token
  if [[ $(tmux show-option -pqv -t "$TMUX_PANE" @agent_type) == process ]]; then
    tmux-agent-status set --agent process --state clear </dev/null
  fi
)

__tmux_task_started() {
  __tmux_task_clear
  unset __tmux_task_active
  local background='(^|[^&])&[[:space:]]*$'
  if [[ $1 =~ $tmux_task_exclude || $1 =~ $background ]]; then
    return 0
  fi

  ((__tmux_task_generation += 1))
  __tmux_task_active="$$-$__tmux_task_generation"
  __tmux_task_minimum_ms=$tmux_task_min_duration_ms
  __tmux_task_started_at=${EPOCHREALTIME/./}
  tmux set-option -p -t "$TMUX_PANE" @fish_task_token "$__tmux_task_active"
  local delay
  printf -v delay '%d.%03d' "$((__tmux_task_minimum_ms / 1000))" "$((__tmux_task_minimum_ms % 1000))"
  bash "$__tmux_task_timer" "$__tmux_task_active" "$delay" </dev/null >/dev/null 2>&1 &
  disown "$!"
  return 0
}

__tmux_task_report() (
  local exit_status=$1 duration_ms=$2 token=$3
  tmux wait-for -L "$__tmux_task_lock" || return
  trap 'tmux wait-for -U "$__tmux_task_lock"' EXIT
  [[ $(tmux show-option -pqv -t "$TMUX_PANE" @fish_task_token) == "$token" ]] || return 0
  tmux set-option -pu -t "$TMUX_PANE" @fish_task_token
  local agent_type agent_status state=clear
  agent_type=$(tmux show-option -pqv -t "$TMUX_PANE" @agent_type)
  agent_status=$(tmux show-option -pqv -t "$TMUX_PANE" @agent_status)
  if [[ $agent_type == process || -z $agent_status ]]; then
    if ((duration_ms >= __tmux_task_minimum_ms)); then
      state="done"
      ((exit_status == 0)) || state=error
    fi
    tmux-agent-status set --agent process --state "$state" </dev/null
  fi
)

__tmux_task_finished() {
  local exit_status=$?
  [[ -n ${__tmux_task_active-} ]] || return 0
  local now=${EPOCHREALTIME/./} token=$__tmux_task_active
  unset __tmux_task_active
  __tmux_task_report "$exit_status" "$(((now - __tmux_task_started_at) / 1000))" "$token"
  return 0
}

__tmux_task_exit() {
  local exit_status=$?
  __tmux_task_clear
  return "$exit_status"
}

# shellcheck disable=SC2034
preexec_functions+=(__tmux_task_started)
# shellcheck disable=SC2034
precmd_functions+=(__tmux_task_finished)
if [[ -z $(trap -p EXIT) ]]; then
  trap __tmux_task_exit EXIT
fi
