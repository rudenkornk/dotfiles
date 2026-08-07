#!/usr/bin/env bash
# Per-tab agent STATUS icon (rendered after the tab name, via tmux-agent-label).
#
# The option stores the semantic state name; all presentation (glyphs, colors)
# lives in tmux-agent-label, which renders the option into the status line.
#
# Usage: agent-status set --state <running|waiting|done|error|clear> [--emit-json]
set -euo pipefail

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
  tmux set-option -w -t "$win" @agent_status "$state"
  # Force an immediate status redraw so the flip is instant.
  tmux refresh-client -S 2>/dev/null || true
fi

finish
exit 0
