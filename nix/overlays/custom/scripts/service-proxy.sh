# shellcheck shell=bash

user_services=(podman)
declare -A remap_services=([docker]=dockerd)
proxy_vars=(HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY http_proxy https_proxy all_proxy no_proxy)

usage() {
  echo "Usage: service-proxy {enable|disable} SERVICE"
  echo "Load proxy secrets into one service until disable or reboot. Podman targets the user service."
  echo "Restart active services only; daemon operations may be interrupted."
}

if [[ $# -eq 1 && ("$1" == --help || "$1" == -h) ]]; then
  usage
  exit 0
fi
if [[ $# -ne 2 || ("$1" != enable && "$1" != disable) ]]; then
  usage >&2
  exit 1
fi

service=${2%.service}
if [[ ! "$service" =~ ^[a-zA-Z0-9_@:.\-]+$ || "$service" == .* ]]; then
  echo "Invalid service name: $2" >&2
  exit 1
fi
unit="$service.service"
ctl=(systemctl)
privileged=(sudo)
runtime=/run
unit_directory=/run/systemd/system
for user_service in "${user_services[@]}"; do
  if [[ "$service" == "$user_service" ]]; then
    ctl+=(--user)
    privileged=()
    runtime=${XDG_RUNTIME_DIR:?}
    unit_directory="$runtime/systemd/user"
    break
  fi
done

load_state=$("${privileged[@]}" "${ctl[@]}" show --property=LoadState --value "$unit")
if [[ "$load_state" != loaded ]]; then
  echo "Service is not loaded: $unit ($load_state)" >&2
  exit 1
fi

environment_directory="$runtime/service-proxy"
environment_file="$environment_directory/$unit.env"
dropin_directory="$unit_directory/$unit.d"
dropin="$dropin_directory/90-service-proxy.conf"

if [[ "$1" == enable ]]; then
  temporary=$(mktemp -d)
  trap 'rm -rf -- "$temporary"' EXIT
  (
    unset "${proxy_vars[@]}"
    export PROXY_APP=${remap_services[$service]:-$service}
    {
      @bashSecrets@
    } >&2
    has_proxy=false
    for variable in "${proxy_vars[@]}"; do
      value=${!variable-}
      if [[ -n "$value" && "${variable,,}" != no_proxy ]]; then
        has_proxy=true
      fi
      if [[ -v "$variable" ]]; then
        value=${value//\\/\\\\}
        value=${value//\"/\\\"}
        value=${value//\$/\\$}
        value=${value//\`/\\\`}
        printf '%s="%s"\n' "$variable" "$value"
      fi
    done
    "$has_proxy"
  ) >"$temporary/environment" || {
    echo "Warning: no proxy snapshot produced for $unit; service left unchanged." >&2
    exit 0
  }

  environment_reference=${environment_file//\\/\\\\}
  environment_reference=${environment_reference//\"/\\\"}
  environment_reference=${environment_reference//%/%%}
  printf '[Service]\nEnvironmentFile="%s"\n' "$environment_reference" >"$temporary/dropin"
  "${privileged[@]}" install -d -m 0700 "$environment_directory"
  "${privileged[@]}" install -m 0600 "$temporary/environment" "$environment_file"
  "${privileged[@]}" install -d -m 0755 "$dropin_directory"
  "${privileged[@]}" install -m 0644 "$temporary/dropin" "$dropin"
else
  "${privileged[@]}" rm -f -- "$dropin" "$environment_file"
fi

"${privileged[@]}" "${ctl[@]}" daemon-reload
"${privileged[@]}" "${ctl[@]}" try-restart "$unit"
