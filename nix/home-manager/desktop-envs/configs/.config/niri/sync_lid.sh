#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# Resume can replay lid events together, and niri's spawned commands can run out of order.
# Read the current state under the lock and hold it until the output update completes.
exec 9>"${XDG_RUNTIME_DIR}/niri-lid.lock"
flock 9

read -r _ state </proc/acpi/button/lid/*/state
case "$state" in
open) niri msg output eDP-1 on ;;
closed) niri msg output eDP-1 off ;;
*) exit 1 ;;
esac
