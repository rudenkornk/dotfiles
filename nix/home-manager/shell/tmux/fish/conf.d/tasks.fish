status is-interactive; or return
set -q TMUX TMUX_PANE; or return

# Nested shells must not overwrite the owning shell's task or report commands run by an agent.
test "$(tmux display-message -p -t "$TMUX_PANE" '#{pane_pid}')" = "$fish_pid"; or return

set -q tmux_task_min_duration_ms; or set -g tmux_task_min_duration_ms 10000
set -q tmux_task_exclude; or set -g tmux_task_exclude (tr -d '\n' <(status dirname)/../../task-exclude.regex)

set -g __tmux_task_timer (path resolve (status dirname)/../task-timer.fish)
set -g __tmux_task_lock "fish-task-$TMUX_PANE"
set -q __tmux_task_generation; or set -g __tmux_task_generation 0

function __tmux_task_clear
    tmux wait-for -L "$__tmux_task_lock"; or return
    tmux set-option -pu -t "$TMUX_PANE" @fish_task_token
    if test "$(tmux show-option -pqv -t "$TMUX_PANE" @agent_type)" = process
        tmux-agent-status set --agent process --state clear </dev/null
    end
    tmux wait-for -U "$__tmux_task_lock"
end

function __tmux_task_started --on-event fish_preexec
    __tmux_task_clear
    set -e __tmux_task_active
    if string match -rq -- "$tmux_task_exclude" "$argv[1]"
        or string match -rq -- '(^|[^&])&\s*$' "$argv[1]"
        return
    end

    set -g __tmux_task_generation (math $__tmux_task_generation + 1)
    set -g __tmux_task_active "$fish_pid-$__tmux_task_generation"
    set -g __tmux_task_minimum_ms "$tmux_task_min_duration_ms"
    tmux set-option -p -t "$TMUX_PANE" @fish_task_token "$__tmux_task_active"
    fish --no-config "$__tmux_task_timer" "$__tmux_task_active" \
        (math "$__tmux_task_minimum_ms / 1000") </dev/null >/dev/null 2>&1 &
    disown $last_pid
end

function __tmux_task_finished --on-event fish_postexec
    set -l exit_status $status
    set -l duration_ms $CMD_DURATION
    set -q __tmux_task_active; or return
    set -l token "$__tmux_task_active"
    set -e __tmux_task_active
    tmux wait-for -L "$__tmux_task_lock"; or return
    if test "$(tmux show-option -pqv -t "$TMUX_PANE" @fish_task_token)" != "$token"
        tmux wait-for -U "$__tmux_task_lock"
        return
    end
    tmux set-option -pu -t "$TMUX_PANE" @fish_task_token
    set -l agent_type (tmux show-option -pqv -t "$TMUX_PANE" @agent_type)
    set -l agent_status (tmux show-option -pqv -t "$TMUX_PANE" @agent_status)
    if test "$agent_type" = process; or test -z "$agent_status"
        set -l state clear
        if test "$duration_ms" -ge "$__tmux_task_minimum_ms"
            set state done
            test "$exit_status" -eq 0; or set state error
        end
        tmux-agent-status set --agent process --state "$state" </dev/null
    end
    tmux wait-for -U "$__tmux_task_lock"
end

function __tmux_task_exit --on-event fish_exit
    __tmux_task_clear
end
