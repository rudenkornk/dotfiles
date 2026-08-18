# shellcheck shell=bash

shopt -s nullglob
umask 077

retry=false
symlink=""
recursive=false
has_failures=false

while [[ $# -gt 0 ]]; do
  case "$1" in
  --retry)
    retry=true
    shift
    ;;
  --symlink)
    symlink="$2"
    shift 2
    ;;
  --recursive)
    recursive=true
    shift
    ;;
  *)
    break
    ;;
  esac
done

arg="$1"
arg="${arg%/}"

get_decrypted_name() {
  local -r file="$1"
  local normalized_name
  local stem
  local extension
  normalized_name=$(basename "$file")
  if [[ "$normalized_name" == *.sops ]]; then
    normalized_name="${normalized_name%.sops}"
  elif [[ "${normalized_name%.*}" == *.sops ]]; then
    extension=".${normalized_name##*.}"
    normalized_name="${normalized_name%.*}"
    normalized_name="${normalized_name%.sops}$extension"
  fi
  stem="${normalized_name%.*}"
  extension="${normalized_name#"$stem"}"
  if [[ -z "$stem" || "$extension" = "." ]]; then
    stem="$normalized_name"
    extension=""
  fi
  printf '%s_%s_decrypted%s\n' "$stem" "$(sha1sum "$file" | head -c 10)" "$extension"
}

decrypt_file() {
  local -r file="$1"
  local -r symlink_target="${2:-}"
  local -r decrypted_name=$(get_decrypted_name "$file")
  local -r decrypted=/run/user/"$(id --user)"/secrets/"$decrypted_name"
  local -r failed="$decrypted.failed"
  local temporary_decrypted
  local error_output
  local status

  if [[ -f "$failed" && "$retry" = true ]]; then
    rm -- "$failed"
  fi

  if [[ ! -f "$decrypted" && ! -f "$failed" ]]; then
    mkdir --parents "$(dirname "$decrypted")"
    temporary_decrypted=$(mktemp "$decrypted.XXXXXX")
    error_output=$(mktemp "$failed.XXXXXX")
    if sops --decrypt "$file" >"$temporary_decrypted" 2>"$error_output"; then
      mv -- "$temporary_decrypted" "$decrypted"
      rm -- "$error_output"
      echo "$file is decrypted and cached." >&2
    else
      status=$?
      rm -- "$temporary_decrypted"
      {
        printf 'Decryption failed with exit status %d.\n' "$status"
        printf 'Reproduce with: sops --decrypt %q\n' "$file"
        printf '\nSops stderr:\n'
        cat "$error_output"
      } >"$failed"
      rm -- "$error_output"
      echo "$file is failed to decrypt." >&2
    fi
  fi

  if [[ -f "$failed" ]]; then
    if [[ -n "$symlink_target" ]]; then
      rm -f -- "$symlink_target"
    fi
    echo /dev/null
    return 1
  fi

  if [[ -n "$symlink_target" ]]; then
    mkdir --parents "$(dirname "$symlink_target")"
    ln -sf "$decrypted" "$symlink_target"
  fi

  echo "$decrypted"
}

if [[ "$recursive" = true && -d "$arg" ]]; then
  while IFS= read -r -d '' file; do
    symlink_target=""
    if [[ -n "$symlink" ]]; then
      rel_path="${file#"$arg/"}"
      dir=$(dirname "$rel_path")
      name=$(basename "$rel_path")
      symlink_target="$symlink/$dir/${name/.sops/}"
    fi
    if ! decrypt_file "$file" "$symlink_target"; then
      has_failures=true
    fi
  done < <(find "$arg" -type f \( -name "*.sops" -o -name "*.sops.*" \) -print0 | sort -z)
elif [[ -n "$arg" ]]; then
  if ! decrypt_file "$arg" "$symlink"; then
    has_failures=true
  fi
fi

if [[ "$has_failures" = true ]]; then
  exit 1
fi
