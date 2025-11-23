#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

shopt -s nullglob

age_key_name="age_key"
age_key_enc_name="age_key.age"
age_key_pub_name="age_key.pub"
age_key_hint_name="age_key_hint.txt"

function usage() {
  echo "Usage: $0 <encrypt|decrypt> <source_dir> <target_dir>"
}

function main() {
  cmd="${1:-usage}"
  source_dir="${2:-.}"
  target_dir="${3:-"$source_dir"}"

  if [[ "$cmd" == "encrypt" ]]; then
    encrypt "$source_dir" "$target_dir"
  elif [[ "$cmd" == "decrypt" ]]; then
    decrypt "$source_dir" "$target_dir"
  else
    usage
  fi
}

function encrypt() {
  source_dir="$1"
  target_dir="$2"

  mkdir --parents "$target_dir"

  # Do not put private key to target directory:
  # target directory is usually located on external storage
  # and even after deletion it may stuck in trash or just inside hard drive
  # without fs link to it.
  age_key_path="$source_dir/$age_key_name"
  age_key_enc_path="$target_dir/$age_key_enc_name"
  age_key_pub_path="$target_dir/$age_key_pub_name"
  age_key_hint_path="$target_dir/$age_key_hint_name"

  if [[ ! -f "$age_key_enc_path" ]]; then
    echo "Generating age key pair..."
    age-keygen --output "$age_key_path"
    age-keygen -y --output "$age_key_pub_path" "$age_key_path"

    echo "Encrypting age key with password..."
    age --passphrase --armor --output "$age_key_enc_path" "$age_key_path"

    read -r -p "Enter hint for age key password: " age_key_hint
    echo "$age_key_hint" >"$age_key_hint_path"
  fi
  if [[ ! -f "$age_key_pub_path" ]]; then
    echo "Public age key not found at $age_key_pub_path"
    echo "Exiting."
    exit 1
  fi

  echo "Copying encryption script to target directory..."
  cp --force "$0" "$target_dir"

  recipient=$(cat "$age_key_pub_path")
  echo "Using recipient: $recipient"

  for file in "$source_dir"/*.tgz; do
    echo "Encrypting $file..."
    age --recipient "$recipient" --output "$target_dir/$(basename "$file").age" "$file"
  done

  echo "All files encrypted successfully."
  echo "Removing unencrypted age key..."
  rm "$age_key_path"
  echo "Done."
}

function decrypt() {
  source_dir="$1"
  target_dir="$2"

  mkdir --parents "$target_dir"

  age_key_path="$target_dir/$age_key_name"
  age_key_enc_path="$source_dir/$age_key_enc_name"
  age_key_hint_path="$source_dir/$age_key_hint_name"

  echo "Decrypting age key with password..."
  if [[ ! -f "$age_key_hint_path" ]]; then
    echo "Error: Hint file for age key password not found at $age_key_hint_path"
    echo "Please ensure the file exists (did you run the encrypt step?)"
    exit 1
  fi
  echo "Hint for age key password: $(cat "$age_key_hint_path")"
  age --decrypt --output "$age_key_path" "$age_key_enc_path"

  for file in "$source_dir"/*.tgz.age; do
    echo "Decrypting $file..."
    age --decrypt --identity "$age_key_path" --output "$target_dir/$(basename "${file%.age}")" "$file"
  done

  echo "Removing unencrypted age key..."
  rm "$age_key_path"
  echo "Done."
}

main "$@"
