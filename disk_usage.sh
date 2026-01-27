#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/utils.sh"

get_read_write() {
  disk_mount=$1
  disk_device=$2
  system=$(uname -s)

  case "$system" in
  Linux | Darwin | OpenBSD)
    # Be careful with modification of iostat, df and other tools arguments.
    # Platform-specific versions of these tools have different sets of arguments.
    # Current version was crafted as subset of options, which supported on all three platforms.
    if [[ -z "$disk_device" ]]; then
      disk_device=$(df "$disk_mount" | tail -1 | cut -d " " -f1)
      if [[ "$system" = @(Darwin|OpenBSD) ]]; then
        disk_device=$(basename "$disk_device")
      fi
    fi
    iostat -d "$disk_device" 1 2 |
      grep --invert-match --extended-regexp '^[[:space:]]*$' |
      tail -1 |
      awk '{printf "%f %f", $3 / 1024, $4 / 1024}'
    ;;

  CYGWIN* | MINGW32* | MSYS* | MINGW*)
    # TODO
    ;;
  esac
}

main() {
  disk_mount="$HOME"
  disk_device=""
  write_label=" "
  read_label=" "
  printf_fmt="%4.0fMiB/s"

  get_read_write "$disk_mount" "$disk_device" | awk "{printf \"$write_label$printf_fmt • $read_label$printf_fmt\n\", \$2, \$1}"
}

# run main driver
main
