#!/usr/bin/env bash

# `jq` always prints dot-decimal numbers, which `printf "%.2f"` would reject under a comma-decimal locale.
export LC_NUMERIC=C

input=$(cat)

# Colors.
# shellcheck disable=SC2034
BLACK="\033[30m"
# shellcheck disable=SC2034
BLUE="\033[34m"
CYAN="\033[36m"
GREEN="\033[32m"
# shellcheck disable=SC2034
PURPLE="\033[35m"
RED="\033[31m"
# shellcheck disable=SC2034
WHITE="\033[37m"
YELLOW="\033[33m"

DIM="\033[2m"
RESET="\033[0m"
BOLD="\033[1m"

# Extract all fields in a single jq pass (one value per line):
# the statusline runs on every render, so a dozen separate jq invocations add up.
{
  read -r model
  read -r effort
  read -r thinking
  read -r cwd
  read -r cost_usd
  read -r duration_ms
  read -r used_pct
  read -r ctx_size
  read -r total_input
  read -r cache_read
  read -r rate_5h
  read -r reset_5h
  read -r rate_7d
  read -r reset_7d
} < <(jq -r '
  (.model.display_name // "Unknown Model"),
  (.effort.level // ""),
  (.thinking.enabled // false),
  (.cwd // ""),
  (.cost.total_cost_usd // 0),
  ((.cost.total_duration_ms // 0) | floor),
  (.context_window.used_percentage // ""),
  (.context_window.context_window_size // 0),
  (.context_window.total_input_tokens // 0),
  (.context_window.current_usage.cache_read_input_tokens // 0),
  (.rate_limits.five_hour.used_percentage // ""),
  (.rate_limits.five_hour.resets_at // ""),
  (.rate_limits.seven_day.used_percentage // ""),
  (.rate_limits.seven_day.resets_at // "")
' <<<"$input" 2>/dev/null)

# Fall back to safe defaults if the input was malformed and jq produced nothing.
: "${model:=Unknown Model}" "${cost_usd:=0}" "${duration_ms:=0}"
: "${ctx_size:=0}" "${total_input:=0}" "${cache_read:=0}"

if [ "$thinking" = "true" ]; then
  thinking_icon=" "
else
  thinking_icon="󱍋 "
fi
# Hide the parentheses entirely when the effort level is not reported.
effort_display=""
[ -n "$effort" ] && effort_display=" (${effort})"
cwd_name=$(basename "${cwd:-unknown}")
now=$(date +%s)

# Session cost.
cost_display=$(printf "${GREEN}\$%.2f${RESET}" "$cost_usd")

# Session duration is the harness-reported accumulated runtime.
# For resumed sessions it counts total active runtime, not calendar time since the session was created.
elapsed=$((duration_ms / 1000))
hours=$((elapsed / 3600))
minutes=$(((elapsed % 3600) / 60))
if [ "$hours" -gt 0 ]; then
  duration="${hours}h${minutes}m"
else
  duration="${minutes}m"
fi

# Prints `pct` as an integer percentage: green below `warn_at` percent, yellow below `crit_at`, red otherwise.
color_pct() {
  local pct="$1" warn_at="$2" crit_at="$3"
  local pct_int
  pct_int=$(printf "%.0f" "$pct")
  if [ "$pct_int" -lt "$warn_at" ]; then
    printf "${GREEN}%s%%${RESET}" "$pct_int"
  elif [ "$pct_int" -lt "$crit_at" ]; then
    printf "${YELLOW}%s%%${RESET}" "$pct_int"
  else
    printf "${RED}%s%%${RESET}" "$pct_int"
  fi
}

# Context window.
ctx_k=$((ctx_size / 1000))
# `cache_read` is the number of tokens served from cache in the current request.
cache_k=$((cache_read / 1000))

# If `used_percentage` is absent but token counts are known, compute it ourselves.
if [ -z "$used_pct" ] && [ "$ctx_size" -gt 0 ] && [ "$total_input" -gt 0 ]; then
  used_pct=$((total_input * 100 / ctx_size))
fi

if [ -n "$used_pct" ] && [ "$used_pct" != "0" ]; then
  ctx_k_used=$((total_input / 1000))
  ctx_display="${ctx_k_used}k/${ctx_k}k $(color_pct "$used_pct" 50 80)"
else
  ctx_display="0k/${ctx_k}k 0%"
fi

fmt_reset() {
  local reset_epoch="$1"
  case "$reset_epoch" in '' | *[!0-9]*) return 0 ;; esac
  local remaining h m
  remaining=$((reset_epoch - now))
  [ "$remaining" -le 0 ] && {
    printf "0s"
    return 0
  }
  h=$((remaining / 3600))
  m=$(((remaining % 3600) / 60))
  local d=$((h / 24))
  local hr=$((h % 24))
  # Beyond 9 hours, minute precision is noise, so show hours only.
  if [ "$d" -gt 0 ]; then
    printf "%dd%dh" "$d" "$hr"
  elif [ "$h" -gt 9 ]; then
    printf "%dh" "$h"
  elif [ "$h" -gt 0 ]; then
    printf "%dh%dm" "$h" "$m"
  elif [ "$m" -gt 0 ]; then
    printf "%dm" "$m"
  else
    printf "%ds" "$remaining"
  fi
}

# Rate limits are reported in subscription mode only — the field is absent in API mode.
limits_display=""
if [ -n "$rate_5h" ] || [ -n "$rate_7d" ]; then
  part_5h=""
  part_7d=""
  if [ -n "$rate_5h" ]; then
    part_5h="5h:$(color_pct "$rate_5h" 75 90)"
    left_5h=$(fmt_reset "$reset_5h")
    [ -n "$left_5h" ] && part_5h="${part_5h}${DIM} (${left_5h})${RESET}"
  fi
  if [ -n "$rate_7d" ]; then
    part_7d="7d:$(color_pct "$rate_7d" 75 90)"
    left_7d=$(fmt_reset "$reset_7d")
    [ -n "$left_7d" ] && part_7d="${part_7d}${DIM} (${left_7d})${RESET}"
  fi
  if [ -n "$part_5h" ] && [ -n "$part_7d" ]; then
    limits_display="  ${DIM}limits:${RESET} ${part_5h}  ${part_7d}"
  elif [ -n "$part_5h" ]; then
    limits_display="  ${DIM}limits:${RESET} ${part_5h}"
  else
    limits_display="  ${DIM}limits:${RESET} ${part_7d}"
  fi
fi

printf "${BOLD}${CYAN}%s%s%s${RESET}  ${DIM}dir:${RESET} %s  ${DIM}session:${RESET} %s\n" \
  "$thinking_icon" \
  "$model" \
  "$effort_display" \
  "$cwd_name" \
  "$duration"

printf "${DIM}cost:${RESET} %s  ${DIM}ctx:${RESET} %b  ${DIM}cache:${RESET} %sk%b" \
  "$cost_display" \
  "$ctx_display" \
  "$cache_k" \
  "$limits_display"
