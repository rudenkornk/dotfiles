#!/usr/bin/env bash
# Per-tab agent STATUS icon (rendered after the tab name, via tmux-agent-label).
#
# The option stores the semantic state name; all presentation (glyphs, colors)
# lives in tmux-agent-label, which renders the option into the status line.
#
# Usage: agent-status set --state <running|waiting|done|error|clear> [--emit-json]
set -euo pipefail

# Fire a desktop notification when the agent needs attention but its tmux session is not on screen.
# The session counts as on screen when some client attached to it runs in the focused niri window;
# the agent's own window may be a background tab, since the status icon in the tab bar
# already shows its state. "Focused" implies "in viewport": niri scrolls a window into view
# when focusing it, and exactly one window is focused globally, so multi-monitor and
# scrollable-layout cases need no extra handling.
#
# The terminal is matched by pid, by walking each client's process ancestry
# (client -> [shell ->] terminal) up to the pid niri reports for the focused window.
# Pane processes themselves are children of the tmux server, not of any terminal,
# which is why the walk must start from the client. Pid matching also avoids
# depending on process names (on NixOS kitty's comm is `.kitty-wrapped`).
maybe_notify() {
  local state="$1" prev="$2" win="$3"
  case "$state" in done | waiting | error) : ;; *) return 0 ;; esac
  # Hooks re-fire the same state (e.g. repeated idle prompts); notify only on a real transition.
  [ "$state" != "$prev" ] || return 0

  # Outside niri the visibility question cannot be answered; stay silent rather than spam.
  local focused_json focused_pid
  focused_json="$(niri msg -j focused-window 2>/dev/null || true)"
  [ -n "$focused_json" ] || return 0
  # `null` (no focused window) is fine: the loop below matches nothing and the notification fires.
  focused_pid="$(printf '%s' "$focused_json" | jq -r '.pid // empty' 2>/dev/null || true)"

  local client_pid pid depth stat rest
  while read -r client_pid; do
    pid="$client_pid"
    depth=0
    while [ -n "$pid" ] && [ "$pid" != "$focused_pid" ] && [ "$depth" -lt 16 ]; do
      stat="$(cat /proc/"$pid"/stat 2>/dev/null || true)"
      [ -n "$stat" ] || break
      # `stat` is `pid (comm) state ppid ...`, and comm may contain spaces
      # (e.g. `tmux: server`), so strip through the last `)` before splitting.
      rest="${stat##*) }"
      rest="${rest#* }"
      pid="${rest%% *}"
      depth=$((depth + 1))
    done
    if [ -n "$pid" ] && [ "$pid" = "$focused_pid" ]; then
      return 0 # The agent is on screen; no notification needed.
    fi
  done < <(tmux list-clients -t "$TMUX_PANE" -F '#{client_pid}' 2>/dev/null || true)

  # The pane's foreground process is the agent itself: hooks run while it is still alive.
  local agent
  agent="$(tmux display-message -p -t "$TMUX_PANE" '#{pane_current_command}' 2>/dev/null || true)"
  agent="${agent:-AI agent}"
  # The window name (usually the AI-derived tab name) tells which task this is about.
  notify-send -a "$agent" -u normal "$agent $state" \
    "$(tmux display-message -p -t "$win" '#{window_name}' 2>/dev/null || true)" || true
}

cmd="${1:-}"
[ $# -gt 0 ] && shift || true

state=""
emit_json=0

if [ "$cmd" = "set" ]; then
  while [ $# -gt 0 ]; do
    case "$1" in
    --state)
      state="${2:-}"
      shift 2
      ;;
    --emit-json)
      emit_json=1
      shift
      ;;
    *) shift ;;
    esac
  done
fi

# Some agents (e.g. Gemini) expect the hook to print JSON on stdout, and pipe
# the event JSON in on stdin. Drain stdin so the writer never sees EPIPE, but
# cap it with a timeout: some hook runners leave stdin open and idle, and an
# unbounded `cat` would hang the hook (and thus the agent) forever.
[ -t 0 ] || timeout 0.2 cat >/dev/null 2>&1 || true
finish() { [ "$emit_json" = 1 ] && printf '{}\n' || true; }

# Nothing to set (unknown command, or no --state given).
[ -n "$state" ] || {
  finish
  exit 0
}

# No-op outside tmux, or when we cannot tell which pane we belong to.
if [ -z "${TMUX:-}" ] || [ -z "${TMUX_PANE:-}" ]; then
  finish
  exit 0
fi

case "$state" in
running | waiting | done | error) : ;;
*) state="" ;; # clear / unknown.
esac

win="$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}' 2>/dev/null || true)"
if [ -n "$win" ]; then
  prev="$(tmux show-option -wqv -t "$win" @agent_status 2>/dev/null || true)"
  tmux set-option -w -t "$win" @agent_status "$state"
  # Force an immediate status redraw so the flip is instant.
  tmux refresh-client -S 2>/dev/null || true
  # Hooks must never see notification plumbing on stderr, and must not fail over it.
  maybe_notify "$state" "$prev" "$win" 2>/dev/null || true
fi

finish
exit 0
