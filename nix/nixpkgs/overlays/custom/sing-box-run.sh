# shellcheck shell=bash

shopt -s nullglob

target_config="@default_config@"

while [[ $# -gt 0 ]]; do
  case "$1" in
  -c | --config)
    target_config="$2"
    shift 2
    ;;
  *)
    break
    ;;
  esac
done

if [[ ! -f "$target_config" ]]; then
  echo "Error: Config file '$target_config' not found."
  exit 1
fi

cmd="sing-box run --config <(sops --decrypt '$target_config') --directory /tmp/sing-box-$USER $*"

echo "Command: $cmd"

sudo bash -c "$cmd"
