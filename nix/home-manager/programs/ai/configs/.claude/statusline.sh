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

# Prints `display_text` colored by `metric`: green below `warn_at`, yellow below `crit_at`, red otherwise.
color_pct() {
  local display_text="$1" metric="$2" warn_at="$3" crit_at="$4"
  local metric_int
  metric_int=$(printf "%.0f" "$metric")
  if [ "$metric_int" -lt "$warn_at" ]; then
    printf "${GREEN}%s${RESET}" "$display_text"
  elif [ "$metric_int" -lt "$crit_at" ]; then
    printf "${YELLOW}%s${RESET}" "$display_text"
  else
    printf "${RED}%s${RESET}" "$display_text"
  fi
}

# Formats a duration in seconds as a compact human string.
# Beyond 9 hours, minute precision is noise, so show hours (or days) only.
fmt_duration() {
  local secs="$1"
  [ "$secs" -le 0 ] && {
    printf "0s"
    return 0
  }
  local h m d hr
  h=$((secs / 3600))
  m=$(((secs % 3600) / 60))
  d=$((h / 24))
  hr=$((h % 24))
  if [ "$d" -gt 0 ]; then
    printf "%dd%dh" "$d" "$hr"
  elif [ "$h" -gt 9 ]; then
    printf "%dh" "$h"
  elif [ "$h" -gt 0 ]; then
    printf "%dh%dm" "$h" "$m"
  elif [ "$m" -gt 0 ]; then
    printf "%dm" "$m"
  else
    printf "%ds" "$secs"
  fi
}

# Renders one rate-limit window as `consumed%/onpace% (elapsed/total)`, where
# `onpace%` is the elapsed fraction of the period, i.e. the consumption you'd expect if perfectly paced.
# The percent pair is colored by consumption speed:
# m = (used_frac - elapsed/period) / ((remaining+60s)/period);
# m<0 green, m<0.30 yellow, else red.
# The +60s prevents division by zero when remaining reaches 0 at the moment of reset.
limit_part() {
  local used_pct="$1" reset_epoch="$2" period_secs="$3" total_label="$4"
  local used_pct_int
  used_pct_int=$(printf "%.0f" "$used_pct")
  # Without a reset timestamp we can compute neither pace nor elapsed time.
  case "$reset_epoch" in
  '' | *[!0-9]*)
    printf "%s%%" "$used_pct_int"
    return 0
    ;;
  esac
  local vals m_pct onpace_pct elapsed_secs
  vals=$(awk -v used="$used_pct" -v reset="$reset_epoch" \
    -v now="$now" -v period="$period_secs" '
    BEGIN {
      remaining = reset - now
      if (remaining < 0) remaining = 0
      elapsed = period - remaining
      if (elapsed < 0) elapsed = 0
      m = (used / 100 - elapsed / period) / ((remaining + 60) / period)
      printf "%.0f %.0f %d", m * 100, elapsed / period * 100, elapsed
    }')
  read -r m_pct onpace_pct elapsed_secs <<<"$vals"
  local pct_display
  pct_display=$(color_pct "${used_pct_int}%/${onpace_pct}%" "$m_pct" 0 30)
  printf "%s (%s/%s)" "$pct_display" "$(fmt_duration "$elapsed_secs")" "$total_label"
}

# Context window.
ctx_k=$((ctx_size / 1000))
# `cache_read` is the number of tokens served from cache in the current request.
cache_k=$((cache_read / 1000))

# If `used_percentage` is absent but token counts are known, compute it ourselves; otherwise treat it as 0.
if [ -z "$used_pct" ]; then
  if [ "$ctx_size" -gt 0 ] && [ "$total_input" -gt 0 ]; then
    used_pct=$((total_input * 100 / ctx_size))
  else
    used_pct=0
  fi
fi

ctx_k_used=$((total_input / 1000))
ctx_display="$(color_pct "${used_pct}%" "$used_pct" 50 80) (${ctx_k_used}k/${ctx_k}k)"

# Rate limits are reported in subscription mode only — the field is absent in API mode.
limits_display=""
if [ -n "$rate_5h" ] || [ -n "$rate_7d" ]; then
  part_5h=""
  part_7d=""
  [ -n "$rate_5h" ] && part_5h=$(limit_part "$rate_5h" "$reset_5h" 18000 "5h")
  [ -n "$rate_7d" ] && part_7d=$(limit_part "$rate_7d" "$reset_7d" 604800 "7d")
  if [ -n "$part_5h" ] && [ -n "$part_7d" ]; then
    limits_display="  ${DIM}limits:${RESET} ${part_5h}  ${part_7d}"
  elif [ -n "$part_5h" ]; then
    limits_display="  ${DIM}limits:${RESET} ${part_5h}"
  else
    limits_display="  ${DIM}limits:${RESET} ${part_7d}"
  fi
fi

printf "${BOLD}${CYAN}%s%s%s${RESET}  ${DIM}dir:${RESET} %s  ${DIM}session:${RESET} %s  ${DIM}cost:${RESET} %s\n" \
  "$thinking_icon" \
  "$model" \
  "$effort_display" \
  "$cwd_name" \
  "$duration" \
  "$cost_display"

printf "${DIM}ctx:${RESET} %b  ${DIM}cache:${RESET} %sk%b" \
  "$ctx_display" \
  "$cache_k" \
  "$limits_display"
