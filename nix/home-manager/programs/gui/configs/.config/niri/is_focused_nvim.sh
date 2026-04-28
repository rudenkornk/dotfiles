#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

focused=$(niri msg -j focused-window 2>/dev/null) || {
  echo false
  exit 0
}
echo "Focused window info: $focused" >&2

app_id=$(echo "$focused" | jq -r '.app_id // empty')
echo "Focused window app_id: $app_id" >&2
term_pid=$(echo "$focused" | jq -r '.pid // empty')
echo "Focused window pid: $term_pid" >&2

terminals=("kitty" "foot" "alacritty" "wezterm" "ghostty" "org.wezfurlong.wezterm")
is_terminal=false
for t in "${terminals[@]}"; do [[ "$app_id" == "$t" ]] && is_terminal=true && break; done
[[ "$is_terminal" == false ]] && echo false && exit 0
[[ -z "$term_pid" ]] && echo false && exit 0

# Find the foreground child of the terminal, skipping the "kitten __atexit__" helper (kitty-specific)
prog_pid=$(awk -v ppid="$term_pid" '
  /^PPid:/ && $2 == ppid {
    pid = FILENAME; gsub(".*/proc/", "", pid); gsub("/status", "", pid)
    cmd_file = "/proc/" pid "/comm"
    getline comm < cmd_file; close(cmd_file)
    if (comm != "kitten") { print pid; exit }
  }
' /proc/[0-9]*/status 2>/dev/null)

echo "Program pid: $prog_pid" >&2
[[ -z "$prog_pid" ]] && echo false && exit 0

prog=$(cat /proc/"$prog_pid"/comm 2>/dev/null) || {
  echo false
  exit 0
}
echo "Program name: $prog" >&2

[[ "$prog" == "nvim" ]] && echo true && exit 0
[[ "$prog" != *"tmux"* ]] && echo false && exit 0

session=$(tmux list-clients -F '#{client_pid} #{session_name}' 2>/dev/null |
  awk -v pid="$prog_pid" '$1 == pid { print $2 }')

echo "Session: $session" >&2
[[ -z "$session" ]] && echo false && exit 0

tmux_prog=$(tmux display-message -t "$session" -p '#{pane_current_command}' 2>/dev/null) ||
  {
    echo false
    exit 0
  }
echo "Tmux program: $tmux_prog" >&2

[[ "$tmux_prog" == "nvim" ]] && echo true && exit 0
echo false
