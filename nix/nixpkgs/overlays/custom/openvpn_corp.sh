# shellcheck shell=bash

pins_file=$(sops-cached --retry @corp_pins@)
pin=$(sed -n 's/^user_pin:[[:space:]]*//p' "$pins_file" | head -n 1)
if [[ -z $pin ]]; then
  echo "Failed to extract user_pin from pins file." >&2
  exit 1
fi

config=$(sops-cached --retry @openvpn_config@)

rundir=$(mktemp --directory "/run/user/$(id --user)/openvpn_corp.XXXXXXXX")
sock="$rundir/management.sock"
fifo="$rundir/agent.fifo"
mkfifo "$fifo"
trap 'rm -rf "$rundir"' EXIT

# Background PIN agent: connect to the openvpn management socket (retrying until openvpn creates it)
# and answer PKCS#11 token PIN queries, which openvpn would otherwise ask interactively via systemd-ask-password.
# A repeated query for the same token means the PIN was rejected —
# stop openvpn instead of retrying, to avoid triggering the TPM anti-hammering lockout.
# The fifo carries the agent's answers back into the same socat connection.
(
  # shellcheck disable=SC2094 # The fifo is read and written by different processes, this is not a self-overwrite.
  socat "UNIX-CONNECT:$sock,retry=200,interval=0.1" STDIO <"$fifo" | {
    exec >"$fifo"
    answered=""
    while IFS= read -r line; do
      case $line in
      ">PASSWORD:Need '"*)
        token=${line#*\'}
        token=${token%%\'*}
        if [[ " $answered " == *" $token "* ]]; then
          echo "PIN for token '$token' was rejected, stopping openvpn." >&2
          echo "signal SIGTERM"
        else
          answered="$answered $token"
          printf 'password "%s" "%s"\n' "$token" "$pin"
        fi
        ;;
      esac
    done
  }
) &

# Resolve the pkcs11-enabled openvpn from this wrapper's PATH and pass its absolute path to sudo,
# so the result does not depend on root's PATH.
# Management flags come after `--config`, so they win over any `management` directive inside the config.
sudo "$(command -v openvpn)" --config "$config" \
  --management "$sock" unix \
  --management-client-user "$USER" \
  --management-query-passwords \
  "$@"
