# shellcheck shell=bash

arguments=(
  # Disable network.
  @unshare@ --net
  # Prevent 'Operation not permitted' errors by appearing as pseudo-root in the namespace.
  # https://unix.stackexchange.com/a/370484/500020
  --map-root-user
  @vim@
  # Restricted mode.
  -Z
  # Disable all config files.
  -u DEFAULTS
  # Disable history (`:help shada`).
  -i NONE
  # Disable swap files.
  -n
)

exec "${arguments[@]}" "$@"
