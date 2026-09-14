# shellcheck shell=bash
#
# Cloud SSH.
#
# The standalone `pssh` package is the internal Cloud client, not nixpkgs' Parallel SSH Tools.
# It is needed for enrollment and certificate maintenance; daily connections use OpenSSH.
#
# Install it using the "Installing standalone packages" workflow in readme.md,
# synchronize the Cloud CA keys as described in the Cloud guide, enroll yubikey certs & restart the service:
# ```bash
# pssh yubikey init
# systemctl --user restart ssh-agent-keys.service
# ```
#
# Inspect certificate expiry with `ssh-keygen -L -f ~/.ssh/yubikey-cert.pub`
# and renew through the Cloud tooling when needed.

export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
key="$HOME/.ssh/yubikey.pub"
certificate="$HOME/.ssh/yubikey-cert.pub"

if [[ ! -s $key || ! -s $certificate ]]; then
  echo "Cloud SSH certificate files are absent; skipping YubiKey loading." >&2
  exit 0
fi

if ! key_info=$(ssh-keygen -lf "$key" -E sha256 2>/dev/null) ||
  ! ssh-keygen -Lf "$certificate" >/dev/null 2>&1; then
  echo "Invalid Cloud SSH public key or certificate." >&2
  exit 1
fi
read -r _ fingerprint _ <<<"$key_info"

# Listing fingerprints avoids a signing probe, which could require touching the token.
if identities=$(ssh-add -l 2>/dev/null); then
  if [[ $identities == *" $fingerprint "* ]]; then
    exit 0
  fi
else
  status=$?
  if [[ $status -ne 1 ]]; then
    echo "The ordinary OpenSSH agent is unavailable." >&2
    exit 1
  fi
fi

config=$(sops-cached @skotty_config@)
if ! serial=$(yq -r '.keyring.yubikey.serial // ""' "$config" 2>/dev/null) ||
  [[ ! $serial =~ ^[0-9]+$ ]]; then
  echo "Missing YubiKey serial in the encrypted Skotty configuration." >&2
  exit 1
fi

# The provider enumerates tokens; never submit this PIN to a different or additional YubiKey.
if ! connected=$(ykman list --serials 2>/dev/null) || [[ $connected != "$serial" ]]; then
  echo "Connect only the configured YubiKey, then restart ssh-agent-corp-keys.service." >&2
  exit 0
fi

SSH_ASKPASS_REQUIRE=force SSH_ASKPASS=corp-yubikey-askpass \
  ssh-add -s @pkcs11_provider@ </dev/null
