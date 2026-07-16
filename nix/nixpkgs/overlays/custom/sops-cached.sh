# shellcheck shell=bash

shopt -s nullglob

retry=false
symlink=""
recursive=false

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
  --recurse)
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

decrypt_file() {
  local -r file="$1"
  local -r symlink_target="${2:-}"
  local -r decrypted_name=$(basename "$file")_$(sha1sum "$file" | head -c 10)_decrypted
  local -r decrypted=/run/user/"$(id --user)"/secrets/"$decrypted_name"

  if [[ -f "$decrypted" && "$retry" = true ]]; then
    read -r first_line <"$decrypted"
    if [[ "$first_line" = "# decryption failed" ]]; then
      rm -- "$decrypted"
    fi
  fi

  if [[ ! -f "$decrypted" ]]; then
    mkdir --parents "$(dirname "$decrypted")"
    touch "$decrypted" && chmod 600 "$decrypted"
    if sops --decrypt "$file" >"$decrypted"; then
      echo "$file is decrypted and cached." >&2
    else
      echo "# decryption failed" >"$decrypted"
      echo "$file is failed to decrypt." >&2
    fi
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
    decrypt_file "$file" "$symlink_target"
  done < <(find "$arg" -type f \( -name "*.sops" -o -name "*.sops.*" \) -print0 | sort -z)
elif [[ -n "$arg" ]]; then
  decrypt_file "$arg" "$symlink"
fi
