#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

debug() { echo "$*" >&2; }

is_focused_nvim() {
  local app_id="$1"
  local term_pid="$2"

  local terminals=("kitty" "foot" "alacritty" "wezterm" "ghostty" "org.wezfurlong.wezterm")
  local is_terminal=false
  for t in "${terminals[@]}"; do [[ "$app_id" == "$t" ]] && is_terminal=true && break; done
  debug "Is terminal: $is_terminal"
  [[ "$is_terminal" == false ]] && return 1
  [[ -z "$term_pid" ]] && return 1

  # Find the foreground child of the terminal, skipping the "kitten __atexit__" helper (kitty-specific)
  local prog_pid
  prog_pid=$(pgrep -P "$term_pid" 2>/dev/null | while read -r pid; do
    comm=$(cat /proc/"$pid"/comm 2>/dev/null) || continue
    [[ "$comm" != "kitten" ]] && echo "$pid" && break
  done)

  debug "Program pid: $prog_pid"
  [[ -z "$prog_pid" ]] && return 1

  local prog
  prog=$(cat /proc/"$prog_pid"/comm 2>/dev/null) || return 1
  debug "Program name: $prog"

  [[ "$prog" == "nvim" ]] && return 0
  [[ "$prog" != "tmux"* ]] && return 1

  local session
  session=$(tmux list-clients -F '#{client_pid} #{session_name}' 2>/dev/null |
    awk -v pid="$prog_pid" '$1 == pid { print $2 }')
  debug "Tmux session: $session"
  [[ -z "$session" ]] && return 1

  local tmux_prog
  tmux_prog=$(tmux display-message -t "$session" -p '#{pane_current_command}' 2>/dev/null) ||
    return 1
  debug "Tmux program: $tmux_prog"

  [[ "$tmux_prog" == "nvim" ]] && return 0
  return 1
}

focused=$(niri msg -j focused-window 2>/dev/null) || exit 0

app_id=$(echo "$focused" | jq -r '.app_id // empty')
debug "Focused window app_id: $app_id"
term_pid=$(echo "$focused" | jq -r '.pid // empty')
debug "Focused window pid: $term_pid"

if is_focused_nvim "$app_id" "$term_pid"; then
  debug "Neovim in focus, sending ctrl-q"
  wtype -M ctrl -k q -m ctrl
else
  debug "Neovim not in focus, using switch-layout"
  niri msg action switch-layout next
fi
