#!/usr/bin/env bash
set -euo pipefail

root=$(arc rev-parse --show-toplevel)
prefix=$(arc rev-parse --show-prefix)

# Delta expects Git's pager convention: repository-root cwd and the original directory in GIT_PREFIX.
cd "$root"
export GIT_PREFIX="$prefix"
exec delta "$@"
