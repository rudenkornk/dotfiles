#!/usr/bin/env bash
# Per-tab AI-generated tab NAME, sibling of tmux-agent-status.
#
# The single entry point for all naming material: callers either push text they consider
# a good task description, or ask the script to pull the agent-authored pane title.
# The name is distilled from that material locally (the summary is already the running agent's
# own generation, so no external model is involved); the script owns the whole update sequence.
#
# Usage: tmux-agent-name set --source <kind> [options]
#   --source title:      Pull the agent-authored pane title (the terminal summary channel).
#   --source summary:    An AI-generated summary passed explicitly with --text.
#   --source prompt:     A user prompt, from --text or from hook JSON on stdin (`prompt` field).
#   --source codex-transcript: Best-effort extraction from the Codex transcript file passed with --path.
#
# Options:
#   --window <id> / --pane <id>: Target window and pane; by default derived from $TMUX_PANE,
#                                which hooks inherit from the agent's own environment.
#   --text <text> / --path <file>: The material, depending on the source.
#   --emit-json: Print `{}` on exit for hook runners that expect JSON output (e.g. Gemini).
#
# Per-window state:
#   @agent_name_material: The material the current name was derived from; dedupes re-fires.
#   @agent_name_refresh:  Whether the name may still be updated; unset means true.
#                         Stable sources (title, summary) keep it true and re-fire on change,
#                         noisy ones (prompt, codex-transcript) set it to false, locking the name.
#   @agent_name_user:     The tab name the window had before the first rename
#                         (or the `<automatic>` sentinel when it was auto-named).
#                         Doubles as the ownership marker: tmux-agent-label restores from it
#                         and drops all of the state above when the agent exits.
set -euo pipefail

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
codex-transcript)
  [ -n "$path" ] || usage_error "--source codex-transcript requires --path"
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

flag="$(tmux show-option -wqv -t "$win" @agent_name_refresh 2>/dev/null || true)"
last="$(tmux show-option -wqv -t "$win" @agent_name_material 2>/dev/null || true)"
if [ "$flag" = "false" ] || [ "$material" = "$last" ]; then
  finish
  exit 0
fi

# Distill a two-word tab name from the material. `stop` holds the words that carry no task
# identity - articles, prepositions, and the generic verbs summaries open with - one arg each
# so the whole-word matching below has clean boundaries.
stop=" $(
  printf '%s ' \
    a an the \
    and or \
    for from in into of on to via with \
    can could "do" does did is are be was were will would should \
    i ll me my our ours us we you your yours \
    it its that this these those they them their theirs \
    new no now old please yes \
    \
    add adds added adding \
    allow allows allowed allowing \
    amend amends amended amending \
    analyze analyzes analyzed analyzing \
    build builds built building \
    check checks checked checking \
    compare compares compared comparing \
    create creates created creating \
    debug debugs debugged debugging \
    enable enables enabled enabling \
    fix fixes fixed fixing \
    implement implements implemented implementing \
    inspect inspects inspected inspecting \
    investigate investigates investigated investigating \
    make makes made making \
    refactor refactors refactored refactoring \
    research researches researched researching \
    rewrite rewrites rewrote rewriting \
    run runs ran running \
    set sets setting \
    support supports supported supporting \
    test tests tested testing \
    trace traces traced tracing \
    update updates updated updating \
    use uses used using \
    verify verifies verified verifying \
    :
)"

# Lowercase, then split on anything that is not an identifier char (keeps foo_bar and foo-bar whole).
words="$(printf '%s' "$material" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_-' ' ')"

# Keep the first two distinctive (non-stopword) tokens.
name=""
count=0
for token in $words; do
  case "$stop" in *" $token "*) continue ;; esac
  name="$name $token"
  count=$((count + 1))
  [ "$count" -ge 2 ] && break
done
# An all-stopword summary falls back to its first two tokens verbatim.
[ -n "$name" ] || name="$words"
name="$(printf '%s' "$name" | tr -s ' ' '\n' | grep -m2 . | paste -sd- - | cut -c1-25 || true)"

if [ -z "$name" ]; then
  finish
  exit 0
fi

# On the first rename, remember the tab name the user had, so it can be restored on agent exit.
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

# `rename-window` also flips this window's automatic-rename off, so the name sticks.
tmux rename-window -t "$win" "$name" 2>/dev/null || true
tmux set-option -w -t "$win" @agent_name_material "$material" 2>/dev/null || true
tmux set-option -w -t "$win" @agent_name_refresh "$refresh" 2>/dev/null || true

finish
exit 0
