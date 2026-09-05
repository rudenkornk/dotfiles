# shellcheck shell=bash

platform_args=()
if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
  platform_args=(-platform wayland)
fi

# "Warm up" sudo before running it under nohup, to avoid failure.
sudo true

# Redirect both stdout and stderr to a log file.
# Otherwise, nohup will create unnecessary nohup.out in cwd.
nohup sudo \
  DISPLAY="$DISPLAY" \
  WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" \
  XAUTHORITY="${XAUTHORITY:-}" \
  XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}" \
  Throne "${platform_args[@]}" "$@" &>/tmp/Throne_"$USER".log &

disown
