#!/usr/bin/env bash
# The single tab-bar fragment: emits a window's agent icon + status icon.
# Invoked from tmux as: #(tmux-agent-label #{window_id})
set -euo pipefail

win="${1:-}"
[ -n "$win" ] || exit 0

match_agent() {
  case "$1" in
  *cursor-agent*) printf '#[fg=#dadada] #[fg=default]' ;;
  *claude*) printf '#[fg=#d97757] #[fg=default]' ;;
  *codex*) printf '#[fg=#10a37f] #[fg=default]' ;;
  *gemini*) printf '#[fg=#4796e3] #[fg=default]' ;;
  *opencode*) printf '#[fg=#9aa5ce]󱞟 #[fg=default]' ;;
  *) : ;;
  esac
}

# The second argument is the agent's own icon color, so a running agent's
# status glyph matches the color of its identity icon.
render_status() {
  local color="${2:-default}"
  case "$1" in
  running) printf '#[fg=%s]#[fg=default]' "$color" ;;
  waiting) printf '#[fg=#f5680a]⏸ #[fg=default]' ;;
  done) printf '#[fg=#9ece6a]󰸞 #[fg=default]' ;;
  error) printf '#[fg=#db4b4b] #[fg=default]' ;;
  *) : ;;
  esac
}

# Print the command lines of the process subtree rooted at $1 (inclusive),
# found via a breadth-first walk over a single ps snapshot.
subtree_args() {
  local root="$1" snap pids frontier next kids k
  [ -n "$root" ] || return 0
  snap="$(ps -eo pid=,ppid=,args= 2>/dev/null || true)"
  [ -n "$snap" ] || return 0

  pids=" $root "
  frontier="$root"
  while [ -n "$frontier" ]; do
    next=""
    kids="$(printf '%s\n' "$snap" | awk -v set=" $frontier " '$2 && index(set, " " $2 " ") {print $1}')"
    for k in $kids; do
      case "$pids" in
      *" $k "*) : ;;
      *)
        pids="$pids$k "
        next="$next $k"
        ;;
      esac
    done
    frontier="$next"
  done

  printf '%s\n' "$snap" | awk -v ids="$pids" 'index(ids, " " $1 " ") { $1=""; $2=""; print }'
}

# Identity glyph for a whole window: first agent found across any of its panes.
# Keying on the window (not the active pane) shows the icon regardless of focus.
detect_window() {
  local w="$1" pid out
  while read -r pid; do
    [ -n "$pid" ] || continue
    out="$(match_agent "$(subtree_args "$pid")")"
    if [ -n "$out" ]; then
      printf '%s' "$out"
      return 0
    fi
  done < <(tmux list-panes -t "$w" -F '#{pane_pid}' 2>/dev/null || true)
}

icon="$(detect_window "$win")"
status="$(tmux show-option -wqv -t "$win" @agent_status 2>/dev/null || true)"

# No agent -> no label at all. Also drop a leftover status, so an agent
# started later in this window does not inherit its predecessor's state.
if [ -z "$icon" ]; then
  [ -z "$status" ] || tmux set-option -wu -t "$win" @agent_status 2>/dev/null || true
  # `@agent_name_user` is the ownership marker set by tmux-agent-name on its first attempt:
  # absent means the window's name was never touched and is not ours to manage.
  # Present means restore the saved tab name (or re-enable auto-naming for the
  # `<automatic>` sentinel, which must match tmux-agent-name) and drop all naming state.
  user_name="$(tmux show-option -wqv -t "$win" @agent_name_user 2>/dev/null || true)"
  if [ -n "$user_name" ]; then
    tmux set-option -wu -t "$win" @agent_name_material 2>/dev/null || true
    tmux set-option -wu -t "$win" @agent_name_refresh 2>/dev/null || true
    tmux set-option -wu -t "$win" @agent_name_user 2>/dev/null || true
    if [ "$user_name" = "<automatic>" ]; then
      tmux set-option -w -t "$win" automatic-rename on 2>/dev/null || true
    else
      tmux rename-window -t "$win" "$user_name" 2>/dev/null || true
    fi
  fi
  exit 0
fi

# The agent icon carries its brand color as a leading `#[fg=#rrggbb]`; extract it
# so the running status glyph can be tinted to match.
agent_color="${icon#*fg=}"
agent_color="${agent_color%%]*}"

# Leading space separates the label from the window name.
status_out="$(render_status "$status" "$agent_color")"
if [ -n "$status_out" ]; then
  printf ' %s%s' "$icon" "$status_out"
else
  printf ' %s' "$icon"
fi
