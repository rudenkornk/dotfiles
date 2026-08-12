#!/usr/bin/env bash
# Theme-agnostic installer for the agent tab-bar label.
#
# Run it AFTER the theme has been loaded, e.g. from tmux.conf:
#   run-shell "tmux-agent-install-format"
set -euo pipefail

LABEL="#(tmux-agent-label #{window_id})"

# Literal (non-regex) first-occurrence replace. ENVIRON avoids awk -v's
# backslash processing, so format strings pass through untouched.
litreplace() {
  S="$1" F="$2" R="$3" awk 'BEGIN {
    s = ENVIRON["S"]; f = ENVIRON["F"]; r = ENVIRON["R"]
    i = index(s, f)
    if (i) printf "%s", substr(s, 1, i - 1) r substr(s, i + length(f))
    else printf "%s", s
  }'
}

inject() {
  local opt="$1" out
  out="$(tmux show-option -gqv "$opt" 2>/dev/null || true)"
  [ -n "$out" ] || return 0

  # Remove our own fragment if a previous run added it, so we re-splice exactly
  # one copy instead of stacking duplicates on every reload.
  out="$(litreplace "$out" "$LABEL" "")"

  # Splice the label right after the window name #W (or #{window_name}).
  if [[ "$out" == *'#W'* ]]; then
    out="$(litreplace "$out" '#W' "#W${LABEL}")"
  elif [[ "$out" == *'#{window_name}'* ]]; then
    out="$(litreplace "$out" '#{window_name}' "#{window_name}${LABEL}")"
  else
    out="${out}${LABEL}"
  fi

  tmux set-option -g "$opt" "$out"
}

inject window-status-format
inject window-status-current-format
