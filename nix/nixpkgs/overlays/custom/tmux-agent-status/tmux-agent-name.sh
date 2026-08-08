#!/usr/bin/env bash
# Per-tab AI-generated tab NAME, sibling of tmux-agent-status.
#
# The single entry point for all naming material: callers either push text they consider
# a good task description, or ask the script to pull the agent-authored pane title.
# The script owns the whole update sequence: state checks, the model call, sanitizing and the rename.
#
# Usage: tmux-agent-name set --source <kind> [options]
#   --source title:      Pull the agent-authored pane title (the terminal summary channel).
#   --source summary:    An AI-generated summary passed explicitly with --text.
#   --source prompt:     A user prompt, from --text or from hook JSON on stdin (`prompt` field).
#   --source transcript: Best-effort extraction from the transcript file passed with --path.
#
# Options:
#   --window <id> / --pane <id>: Target window and pane; by default derived from $TMUX_PANE,
#                                which hooks inherit from the agent's own environment.
#   --text <text> / --path <file>: The material, depending on the source.
#   --emit-json: Print `{}` on exit for hook runners that expect JSON output (e.g. Gemini).
#
# Per-window state:
#   @agent_named:         `pending` while a model call is in flight, then the chosen name.
#   @agent_name_material: The material text the current name was derived from.
#   @agent_name_refresh:  Whether the name may still be updated; unset means true.
#                         Stable sources (title, summary) keep it true and re-fire on change,
#                         noisy ones (prompt, transcript) set it to false, locking the name.
#   @agent_name_tries:    Failed model calls for the current material.
#   @agent_name_user:     The tab name the window had before the first naming attempt
#                         (or the `<automatic>` sentinel when it was auto-named).
#                         Doubles as the ownership marker: tmux-agent-label restores from it
#                         and drops all of the state above when the agent exits.
set -euo pipefail

# How many failed model calls to tolerate per material before giving up on it.
max_tries=3
model=openrouter/auto
# Must match the sentinel in tmux-agent-label.
automatic_sentinel="<automatic>"

cmd="${1:-}"
[ $# -gt 0 ] && shift || true

source_kind=""
text=""
path=""
win=""
pane=""
emit_json=0

if [ "$cmd" = "set" ]; then
  while [ $# -gt 0 ]; do
    case "$1" in
    --source)
      source_kind="${2:-}"
      shift 2
      ;;
    --text)
      text="${2:-}"
      shift 2
      ;;
    --path)
      path="${2:-}"
      shift 2
      ;;
    --window)
      win="${2:-}"
      shift 2
      ;;
    --pane)
      pane="${2:-}"
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

# Some hook runners pipe event JSON on stdin and expect JSON on stdout. Read stdin early
# and bounded: it may carry prompt material, and draining it spares the writer an EPIPE.
stdin_json=""
[ -t 0 ] || stdin_json="$(timeout 0.5 cat 2>/dev/null || true)"
finish() { [ "$emit_json" = 1 ] && printf '{}\n' || true; }

# Usage errors are caller bugs and fail loudly, unlike the environmental no-ops
# (outside tmux, no material yet, dedupe), which stay silent by design.
# Exit 1, never 2: some hook runners interpret 2 as "block the agent's action".
usage_error() {
  printf 'tmux-agent-name: %s\n' "$1" >&2
  finish
  exit 1
}

[ "$cmd" = "set" ] || usage_error "unknown command: '${cmd}' (expected 'set')"
[ -n "$source_kind" ] || usage_error "missing --source"

# Resolve the target: an explicit --window wins, otherwise it is derived from the pane,
# which itself defaults to $TMUX_PANE. No tmux context at all -> silent no-op.
pane="${pane:-${TMUX_PANE:-}}"
if [ -z "$win" ]; then
  if [ -z "${TMUX:-}" ] || [ -z "$pane" ]; then
    finish
    exit 0
  fi
  win="$(tmux display-message -p -t "$pane" '#{window_id}' 2>/dev/null || true)"
fi
if [ -z "$win" ]; then
  finish
  exit 0
fi

# Agent-authored pane titles are prefixed with a spinner glyph from the U+2000-U+2FFF block,
# whose UTF-8 encoding starts with byte 0xE2, while shell-written titles (paths, commands)
# start with an ASCII character. `LC_ALL=C` makes the glob byte-wise, so the check works in any locale.
title_is_agent_authored() {
  local LC_ALL=C
  case "$1" in
  $'\xe2'*) return 0 ;;
  *) return 1 ;;
  esac
}

material=""
refresh="true"
case "$source_kind" in
title)
  raw="$(tmux display-message -p -t "$pane" '#{pane_title}' 2>/dev/null || true)"
  if title_is_agent_authored "$raw"; then
    # Drop the animated spinner prefix, so the text compares stable across frames.
    material="$(printf '%s' "$raw" | sed 's/^[^[:alnum:]]*//')"
  fi
  ;;
summary)
  [ -n "$text" ] || usage_error "--source summary requires --text"
  material="$text"
  ;;
prompt)
  material="$text"
  [ -n "$material" ] || material="$(printf '%s' "$stdin_json" | jq -r '.prompt // empty' 2>/dev/null || true)"
  refresh="false"
  ;;
transcript)
  [ -n "$path" ] || usage_error "--source transcript requires --path"
  [ -r "$path" ] || usage_error "transcript is not readable: ${path}"
  # Transcripts are JSONL; prefer the latest summary entry, else the latest plain user message.
  # The format is undocumented, so this is best-effort.
  material="$(jq -rs '[.[] | select(.type == "summary") | .summary] | last // empty' "$path" 2>/dev/null || true)"
  [ -n "$material" ] ||
    material="$(jq -rs '[.[] | select(.type == "user") | .message.content | strings] | last // empty' \
      "$path" 2>/dev/null || true)"
  refresh="false"
  ;;
*) usage_error "unknown --source: '${source_kind}'" ;;
esac

# Cap the material, so a huge pasted prompt cannot bloat the model call.
material="$(printf '%s' "$material" | head -c 500)"
if [ -z "$material" ]; then
  finish
  exit 0
fi

named="$(tmux show-option -wqv -t "$win" @agent_named 2>/dev/null || true)"
flag="$(tmux show-option -wqv -t "$win" @agent_name_refresh 2>/dev/null || true)"
last="$(tmux show-option -wqv -t "$win" @agent_name_material 2>/dev/null || true)"
if [ "$named" = "pending" ] || [ "$flag" = "false" ] || [ "$material" = "$last" ]; then
  finish
  exit 0
fi

# Take the lock before going async, so concurrent callers cannot double-fire.
tmux set-option -w -t "$win" @agent_named pending 2>/dev/null || true

# On the first attempt, remember the tab name the user had, so it can be restored on agent exit.
# A window-level `automatic-rename off` means the current name is a manual one worth keeping;
# otherwise the window was auto-named and the sentinel says "hand naming back to tmux".
if [ -z "$(tmux show-option -wqv -t "$win" @agent_name_user 2>/dev/null || true)" ]; then
  if [ "$(tmux show-option -wqv -t "$win" automatic-rename 2>/dev/null || true)" = "off" ]; then
    user_name="$(tmux display-message -p -t "$win" '#{window_name}' 2>/dev/null || true)"
  else
    user_name="$automatic_sentinel"
  fi
  tmux set-option -w -t "$win" @agent_name_user "$user_name" 2>/dev/null || true
fi

# The model call runs in the background, so a hook caller never delays its agent.
(
  # The router may land on reasoning models, which need a generous `max_tokens` to leave room
  # for their thinking (an empty answer otherwise); only a few answer tokens are actually generated.
  body="$(jq -n --arg m "$model" --arg t "$material" '{
    model: $m,
    max_tokens: 2000,
    reasoning: {enabled: false},
    messages: [{
      role: "user",
      content: ("Reply with EXACTLY TWO words most distinctively describing the task. "
        + "No punctuation, no explanation. Task description: " + $t)
    }]
  }')"

  # Latency is spiky, especially on free-pool models: usually seconds, sometimes closer to a minute.
  name="$(curl -sS --max-time 90 https://openrouter.ai/api/v1/chat/completions \
    -H "Authorization: Bearer ${OPENROUTER_API_KEY:-}" \
    -H 'Content-Type: application/json' \
    -d "$body" | jq -r '.choices[0].message.content // empty' || true)"

  # Keep only the first two words, hyphen-joined, and strip whatever decoration the model added.
  name="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_-' '\n' | grep -m2 . | paste -sd- - || true)"
  name="${name:0:25}"

  if [ -n "$name" ]; then
    # `rename-window` also flips this window's automatic-rename off, so the name sticks.
    tmux rename-window -t "$win" "$name" 2>/dev/null || true
    tmux set-option -w -t "$win" @agent_named "$name" 2>/dev/null || true
    tmux set-option -w -t "$win" @agent_name_material "$material" 2>/dev/null || true
    tmux set-option -w -t "$win" @agent_name_refresh "$refresh" 2>/dev/null || true
    tmux set-option -wu -t "$win" @agent_name_tries 2>/dev/null || true
  else
    # Models flake; release the lock so the caller may retry, but only a few times per material.
    # On give-up the material is marked consumed anyway, so a later change starts fresh.
    tries="$(tmux show-option -wqv -t "$win" @agent_name_tries 2>/dev/null || true)"
    tries=$((${tries:-0} + 1))
    if [ "$tries" -ge "$max_tries" ]; then
      tmux set-option -w -t "$win" @agent_name_material "$material" 2>/dev/null || true
      tmux set-option -wu -t "$win" @agent_name_tries 2>/dev/null || true
    else
      tmux set-option -w -t "$win" @agent_name_tries "$tries" 2>/dev/null || true
    fi
    tmux set-option -wu -t "$win" @agent_named 2>/dev/null || true
  fi
) </dev/null >/dev/null 2>&1 &

finish
exit 0
