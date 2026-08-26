# shellcheck shell=bash

set -euo pipefail
umask 077

usage() {
  printf 'Usage: sops-diff FILE [START_REV[..END_REV]]\n'
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 2
fi

start_revision=HEAD
end_revision=
if [[ $# -eq 2 ]]; then
  if [[ "$2" == *..* ]]; then
    start_revision=${2%%..*}
    end_revision=${2#*..}
    start_revision=${start_revision:-HEAD}
  else
    start_revision=$2
  fi
fi

file=$(realpath -- "$1")
if [[ ! -f "$file" ]]; then
  printf 'sops-diff: not a regular file: %s\n' "$1" >&2
  exit 1
fi

worktree=$(git -C "$(dirname -- "$file")" rev-parse --show-toplevel)
worktree=$(realpath -- "$worktree")
repository_path=$(realpath --relative-to="$worktree" -- "$file")
if [[ "$repository_path" == .. || "$repository_path" == ../* || "$repository_path" == /* ]]; then
  printf 'sops-diff: file is outside the Git worktree: %s\n' "$1" >&2
  exit 1
fi
start_commit=$(git -C "$worktree" rev-parse --verify --end-of-options "${start_revision}^{commit}")
end_commit=
if [[ -n "$end_revision" ]]; then
  end_commit=$(git -C "$worktree" rev-parse --verify --end-of-options "${end_revision}^{commit}")
fi

runtime_directory=${XDG_RUNTIME_DIR:-/run/user/$UID}
if [[ ! -d "$runtime_directory" || ! -w "$runtime_directory" ]]; then
  printf 'sops-diff: runtime directory is unavailable: %s\n' "$runtime_directory" >&2
  exit 1
fi
temporary_directory=$(mktemp -d "$runtime_directory/sops-diff.XXXXXXXXXX")
cleanup() {
  rm -rf -- "$temporary_directory"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

basename=$(basename -- "$file")
start_directory="$temporary_directory/start"
end_directory="$temporary_directory/end"
start_decrypted_directory="$temporary_directory/start-decrypted"
end_decrypted_directory="$temporary_directory/end-decrypted"
mkdir -- "$start_directory" "$end_directory" "$start_decrypted_directory" "$end_decrypted_directory"
start_encrypted="$start_directory/$basename"
end_encrypted="$end_directory/$basename"
start_decrypted="$start_decrypted_directory/$basename"
end_decrypted="$end_decrypted_directory/$basename"

git -C "$worktree" show "$start_commit:$repository_path" >"$start_encrypted"
if [[ -n "$end_commit" ]]; then
  git -C "$worktree" show "$end_commit:$repository_path" >"$end_encrypted"
else
  cp -- "$file" "$end_encrypted"
fi
sops --decrypt "$start_encrypted" >"$start_decrypted"
sops --decrypt "$end_encrypted" >"$end_decrypted"

rvim -c "colorscheme **habamax**" -d -- "$start_decrypted" "$end_decrypted"
