# shellcheck shell=bash

umask 077
unset HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY http_proxy https_proxy all_proxy no_proxy

if [[ ${1:-} != --root ]]; then
  profile="${1:-beta}"
  case "$profile" in
  alpha | beta)
    config="@profiles@/$profile-xhttp.json.sops"
    ;;
  -c | --config)
    config="${2:?Expected an encrypted profile path.}"
    ;;
  *)
    echo "Usage: xray-run [alpha|beta] | --config PROFILE.json.sops" >&2
    exit 1
    ;;
  esac
  if [[ -n ${TMUX_PANE:-} ]]; then
    tmux rename-window -t "$TMUX_PANE" xray
    tmux move-window -s "$TMUX_PANE" -t :100 || true
  fi
  sudo -v
  sops --decrypt "$config" | sudo "$0" --root
  exit
fi

if [[ $EUID -ne 0 ]]; then
  echo "The internal --root mode requires sudo." >&2
  exit 1
fi

exec {lock_fd}>/run/lock/xray-run.lock
flock --nonblock "$lock_fd"
if ip -j link | jq -e 'any(.[]; .ifname == "xray-tun" or .ifname == "xray-trial" or .ifname == "throne-tun")' >/dev/null; then
  echo "Stop the existing VPN before launching xray-run." >&2
  exit 1
fi

directory=$(mktemp -d /run/xray-run.XXXXXX)
pid=""
exception=false
interface=""

cleanup() {
  trap '' INT TERM
  if [[ -n $pid ]]; then
    kill -TERM "$pid" 2>/dev/null || true
    wait "$pid" || true
  fi
  rm -f -- "$directory/profile.json" "$directory/config.json"
  rmdir -- "$directory"
  if [[ $exception == true ]]; then
    iptables -w -t mangle -D nixos-fw-rpfilter -i "$interface" \
      -m conntrack --ctstate ESTABLISHED,RELATED \
      -m comment --comment xray-run -j RETURN
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

cat >"$directory/profile.json"
jq -e '.tag == "proxy" and .protocol == "vless" and .streamSettings.network == "xhttp"' \
  "$directory/profile.json" >/dev/null
interface=$(ip -j -4 route show default | jq -er 'sort_by(.metric // 0) | .[0].dev')
resolver=$(resolvectl --json=short dns "$interface" | jq -ec '
  [.[].servers[] | select(.family == 2 and (.addressString | startswith("127.") | not))][0]
  | select(. != null)')
jq --slurpfile profile "$directory/profile.json" --argjson resolver "$resolver" '
  .outbounds = $profile + .outbounds |
  .dns.servers[0].address = $resolver.addressString |
  .dns.servers[0].port = ($resolver.port // 53) |
  .dns.servers[0].domains += ["full:" + $profile[0].settings.vnext[0].address]
' @config@ >"$directory/config.json"
rm -- "$directory/profile.json"
xray run -test -c "$directory/config.json"

# NixOS strict reverse-path checks otherwise reject Wi-Fi replies while the default route points to TUN.
iptables -w -t mangle -I nixos-fw-rpfilter -i "$interface" \
  -m conntrack --ctstate ESTABLISHED,RELATED \
  -m comment --comment xray-run -j RETURN
exception=true
xray run -c "$directory/config.json" &
pid=$!
wait "$pid"
