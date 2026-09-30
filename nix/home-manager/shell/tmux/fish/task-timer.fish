sleep "$argv[2]"

# Invalidation and reporting share a lock so an expired timer cannot overwrite a newer result.
set -l lock "fish-task-$TMUX_PANE"
tmux wait-for -L "$lock"; or exit
if test "$(tmux show-option -pqv -t "$TMUX_PANE" @fish_task_token)" = "$argv[1]"
    if test "$(tmux display-message -p -t "$TMUX_PANE" '#{alternate_on}')" = 1
        tmux set-option -pu -t "$TMUX_PANE" @fish_task_token
    else
        set -l agent_type (tmux show-option -pqv -t "$TMUX_PANE" @agent_type)
        set -l agent_status (tmux show-option -pqv -t "$TMUX_PANE" @agent_status)
        if test "$agent_type" = process; or test -z "$agent_status"
            tmux-agent-status set --agent process --state running </dev/null
        end
    end
end
tmux wait-for -U "$lock"
