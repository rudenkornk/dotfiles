#!/usr/bin/env bash
# The single tab-bar fragment: emits each pane's detected or explicit agent entry.
# Invoked from tmux as: #(tmux-agent-label #{window_id})
set -euo pipefail

win="${1:-}"
[ -n "$win" ] || exit 0

# Generic icons shortlist for AI clis.
#   fa-infinity (U+EDFE).
# 󰁨  md-auto_fix (U+F0068).
# 󰙴  md-creation (U+F0674).
#   fa-biohazard (U+EF35).
#   fae-radioactive (U+E238).
#   fa-flask (U+F0C3).

# Map one candidate executable token (see subtree_exes) to an agent identity.
match_agent() {
  local base="${1##*/}"
  base="${base#.}"
  base="${base%-wrapped}"
  base="${base%.js}"
  base="${base%.mjs}"
  base="${base%.cjs}"
  case "$base" in
  cursor-agent | claude | codex | gemini | opencode-omo | opencode) printf '%s' "$base" ;;
  *) : ;;
  esac
}

render_agent() {
  case "$1" in
  cursor-agent) printf '#[fg=#dadada] #[fg=default]' ;;
  claude) printf '#[fg=#d97757] #[fg=default]' ;;
  codex) printf '#[fg=#10a37f] #[fg=default]' ;;
  gemini) printf '#[fg=#4796e3] #[fg=default]' ;;
  opencode-omo) printf '#[fg=##6ff7f7] #[fg=default]' ;;
  opencode) printf '#[fg=#9aa5ce]󱞟 #[fg=default]' ;;
  process) printf '#[fg=#7aa2f7] #[fg=default]' ;;
  *) : ;;
  esac
}

# The second argument is the agent's own icon color, so a running agent's
# status glyph matches the color of its identity icon.
render_status() {
  local color="${2:-default}"
  case "$1" in
  running) printf '#[fg=%s]#[fg=default]' "$color" ;;
  waiting) printf '#[fg=#ffba0a]⏸ #[fg=default]' ;;
  done) printf '#[fg=#9ece6a]󰸞 #[fg=default]' ;;
  error) printf '#[fg=#db4b4b] #[fg=default]' ;;
  *) : ;;
  esac
}

# Print candidate executable tokens, one per line, for the process subtree rooted at $1
# (inclusive), found via a breadth-first walk over a single ps snapshot.
# Each process contributes its argv[0], plus the script path (the first non-option
# argument) when argv[0] is a script interpreter - which is how gemini runs
# (`node --no-warnings=... .../gemini.js`). File arguments of ordinary programs
# (an editor opening `~/.claude/settings.json`) are deliberately never emitted.
subtree_exes() {
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

  printf '%s\n' "$snap" | awk -v ids="$pids" 'index(ids, " " $1 " ") {
    print $3
    base = $3
    sub(".*/", "", base)
    if (base ~ /^(node|bun|deno|python[0-9.]*)$/)
      for (i = 4; i <= NF; i++) if ($i !~ /^-/) { print $i; break }
  }'
}

detect_pane() {
  local pane="$1" pid="$2" agent tok out
  agent="$(tmux show-option -pqv -t "$pane" @agent_type 2>/dev/null || true)"
  if [ "$agent" = process ]; then
    printf '%s' "$agent"
    return 0
  fi
  while read -r tok; do
    out="$(match_agent "$tok")"
    if [ -n "$out" ]; then
      printf '%s' "$out"
      return 0
    fi
  done < <(subtree_exes "$pid")
}

render_entry() {
  local icon="$1" status="$2" agent_color status_out
  # The agent icon carries its brand color as a leading `#[fg=#rrggbb]`.
  agent_color="${icon#*fg=}"
  agent_color="${agent_color%%]*}"
  status_out="$(render_status "$status" "$agent_color")"
  printf ' %s%s' "$icon" "$status_out"
}

visible=0
while read -r visible_win; do
  if [ "$visible_win" = "$win" ]; then
    visible=1
    break
  fi
done < <(tmux list-clients -F '#{window_id}' 2>/dev/null || true)

has_agent=0
while read -r pane pid; do
  agent="$(detect_pane "$pane" "$pid")"
  status="$(tmux show-option -pqv -t "$pane" @agent_status 2>/dev/null || true)"
  if [ -z "$agent" ]; then
    [ -z "$status" ] || tmux set-option -pu -t "$pane" @agent_status 2>/dev/null || true
    continue
  fi
  [ "$agent" = process ] || has_agent=1

  if [ "$status" = "done" ] && [ "$visible" = 1 ]; then
    tmux set-option -pu -t "$pane" @agent_status \; \
      set-option -pu -t "$pane" @agent_type 2>/dev/null || true
    status=""
  fi

  [ "$agent" != process ] || [ -n "$status" ] || continue
  render_entry "$(render_agent "$agent")" "$status"
done < <(tmux list-panes -t "$win" -F '#{pane_id} #{pane_pid}' 2>/dev/null || true)

if [ "$has_agent" = 0 ]; then
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
fi
