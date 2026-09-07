# shellcheck shell=bash

set -euo pipefail

program="$1"
temporary_directory=$(mktemp -d)
trap 'rm -rf "$temporary_directory"' EXIT

mkdir "$temporary_directory/runtime"
printf invalid >"$temporary_directory/empty.sops"
XDG_RUNTIME_DIR="$temporary_directory/runtime" "$program" \
  --fallback "" --symlink "$temporary_directory/fallback" "$temporary_directory/empty.sops" >/dev/null
test ! -s "$temporary_directory/fallback"

printf invalid >"$temporary_directory/content.sops"
XDG_RUNTIME_DIR="$temporary_directory/runtime" "$program" \
  --fallback fallback --symlink "$temporary_directory/fallback" "$temporary_directory/content.sops" >/dev/null
test "$(cat "$temporary_directory/fallback")" = fallback
