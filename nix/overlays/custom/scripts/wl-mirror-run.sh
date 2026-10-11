# shellcheck shell=bash

source_output=""
destinations=()

list_outputs() {
  if outputs=$(niri msg --json outputs); then
    jq -r '.[] | "  \(.name) (\(if .logical == null then "disabled" else "active" end))"' <<<"$outputs"
  else
    echo "Cannot discover displays. Run this command inside a Niri session." >&2
    return 1
  fi
}

usage() {
  cat <<'EOF'
Usage: wl-mirror-run [--source OUTPUT] [--dest OUTPUT ...]

Mirror the active internal display (eDP-* or LVDS-*) to all active external displays.
With --source, default destinations are all other active displays.
Repeat --dest to select multiple destinations. Displays are selected at startup.
Press Ctrl-C to stop all mirrors.

Options:
  -s, --source OUTPUT  Select the source display.
  -d, --dest OUTPUT    Select a destination display; may be repeated.
  -l, --list           List connected displays and their status.
  -h, --help           Show this help and connected displays.

Examples:
  wl-mirror-run
  wl-mirror-run --source eDP-1 --dest DP-1 --dest HDMI-A-1
  wl-mirror-run --source DP-1 --dest eDP-1

Connected displays:
EOF
  list_outputs || true
}

fail() {
  echo "wl-mirror-run: $*" >&2
  echo "Use --help for usage and --list for available displays." >&2
  exit 1
}

while (($#)); do
  case "$1" in
  -s | --source | -d | --dest)
    (($# >= 2)) || fail "$1 requires an output name."
    if [[ $1 == -s || $1 == --source ]]; then
      source_output=$2
    else
      destinations+=("$2")
    fi
    shift 2
    ;;
  -l | --list)
    list_outputs
    exit
    ;;
  -h | --help)
    usage
    exit
    ;;
  *)
    fail "Unknown argument: $1"
    ;;
  esac
done

outputs=$(niri msg --json outputs)
mapfile -t active_outputs < <(jq -r '.[] | select(.logical != null) | .name' <<<"$outputs")

if [[ -z $source_output ]]; then
  mapfile -t internal_outputs < <(
    jq -r '.[] | select(.logical != null) | .name | select(test("^(eDP|LVDS)-"))' <<<"$outputs"
  )
  ((${#internal_outputs[@]} == 1)) || fail "Expected one active internal display; select one with --source."
  source_output=${internal_outputs[0]}
fi

require_active() {
  local output
  for output in "${active_outputs[@]}"; do
    [[ $output != "$1" ]] || return 0
  done
  echo "Active displays: ${active_outputs[*]:-(none)}" >&2
  fail "Display '$1' is unavailable or disabled."
}

require_active "$source_output"
if ((${#destinations[@]} == 0)); then
  for output in "${active_outputs[@]}"; do
    [[ $output == "$source_output" ]] || destinations+=("$output")
  done
fi
((${#destinations[@]})) || fail "No destination displays are active."

for destination in "${destinations[@]}"; do
  require_active "$destination"
  [[ $destination != "$source_output" ]] || fail "Source and destination must differ."
done

pids=()
trap '
  if ((${#pids[@]})); then
    kill "${pids[@]}" 2>/dev/null || true
    wait "${pids[@]}" 2>/dev/null || true
  fi
' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

launched=()
for destination in "${destinations[@]}"; do
  if [[ " ${launched[*]} " == *" $destination "* ]]; then
    continue
  fi
  echo "Mirroring $source_output → $destination"
  wl-mirror --fullscreen-output "$destination" "$source_output" &
  pids+=("$!")
  launched+=("$destination")
done

status=0
for pid in "${pids[@]}"; do
  wait "$pid" || status=$?
done
exit "$status"
