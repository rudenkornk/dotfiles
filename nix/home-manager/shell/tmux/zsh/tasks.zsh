[[ -o interactive && -n ${TMUX-} && -n ${TMUX_PANE-} ]] || return
[[ $(tmux display-message -p -t "$TMUX_PANE" '#{pane_pid}') = $$ ]] || return

zmodload zsh/datetime
autoload -Uz add-zsh-hook
(( ${+tmux_task_min_duration_ms} )) || typeset -g tmux_task_min_duration_ms=10000
typeset -g __tmux_task_root=${${(%):-%x}:A:h:h}
(( ${+tmux_task_exclude} )) || typeset -g tmux_task_exclude="$(tr -d '\n' < "$__tmux_task_root/task-exclude.regex")"
typeset -g __tmux_task_timer="$__tmux_task_root/task-timer.sh"
typeset -g __tmux_task_lock="fish-task-$TMUX_PANE"
(( ${+__tmux_task_generation} )) || typeset -gi __tmux_task_generation=0

__tmux_task_clear() {
  emulate -L zsh
  # Ctrl-C during a hook must not leave the next command waiting on an orphaned lock.
  {
    tmux wait-for -L "$__tmux_task_lock" || return
    tmux set-option -pu -t "$TMUX_PANE" @fish_task_token
    if [[ $(tmux show-option -pqv -t "$TMUX_PANE" @agent_type) = process ]]; then
      tmux-agent-status set --agent process --state clear </dev/null
    fi
  } always {
    tmux wait-for -U "$__tmux_task_lock"
  }
}

__tmux_task_started() {
  emulate -L zsh
  __tmux_task_clear
  unset __tmux_task_active
  if [[ $1 =~ "$tmux_task_exclude" || $1 =~ '(^|[^&])&[[:space:]]*$' ]]; then
    return 0
  fi

  (( ++__tmux_task_generation ))
  typeset -g __tmux_task_active="$$-$__tmux_task_generation"
  typeset -g __tmux_task_minimum_ms="$tmux_task_min_duration_ms"
  typeset -gF __tmux_task_started_at=$EPOCHREALTIME
  tmux set-option -p -t "$TMUX_PANE" @fish_task_token "$__tmux_task_active"
  bash "$__tmux_task_timer" "$__tmux_task_active" \
    "$(( __tmux_task_minimum_ms / 1000.0 ))" </dev/null >/dev/null 2>&1 &!
}

__tmux_task_finished() {
  local exit_status=$?
  emulate -L zsh
  (( ${+__tmux_task_active} )) || return 0
  local -F duration_ms=$(( (EPOCHREALTIME - __tmux_task_started_at) * 1000 ))
  local token="$__tmux_task_active"
  unset __tmux_task_active
  {
    tmux wait-for -L "$__tmux_task_lock" || return
    if [[ $(tmux show-option -pqv -t "$TMUX_PANE" @fish_task_token) != "$token" ]]; then
      return
    fi
    tmux set-option -pu -t "$TMUX_PANE" @fish_task_token
    local agent_type=$(tmux show-option -pqv -t "$TMUX_PANE" @agent_type)
    local agent_status=$(tmux show-option -pqv -t "$TMUX_PANE" @agent_status)
    if [[ $agent_type = process || -z $agent_status ]]; then
      local state=clear
      if (( duration_ms >= __tmux_task_minimum_ms )); then
        state=done
        (( exit_status == 0 )) || state=error
      fi
      tmux-agent-status set --agent process --state "$state" </dev/null
    fi
  } always {
    tmux wait-for -U "$__tmux_task_lock"
  }
}

__tmux_task_exit() {
  emulate -L zsh
  __tmux_task_clear
}

add-zsh-hook preexec __tmux_task_started
add-zsh-hook precmd __tmux_task_finished
add-zsh-hook zshexit __tmux_task_exit
