# shellcheck shell=bash
# Manages ssh-agent lifecycle and loads sops-encrypted SSH keys.
# Credits: https://gist.github.com/gerbsen/5fd8aa0fde87ac7a2cae

export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"

add_keys() {
  local keys=("$HOME"/.ssh/*.sops)
  for key in "${keys[@]}"; do
    if ssh-add -T "${key%.*}.pub" &>/dev/null; then
      continue
    fi
    sops --decrypt "$key" 2>/dev/null | ssh-add - 2>/dev/null ||
      echo "Failed to load/decrypt key: $(basename "$key")"
  done
}

set +o errexit
ssh-add -l &>/dev/null
agent_status=$?
set -o errexit

if [[ "$agent_status" -eq 2 ]]; then
  echo "Initializing new SSH agent ..."
  rm -f "$SSH_AUTH_SOCK"
  ssh-agent -a "$SSH_AUTH_SOCK" &>/dev/null
fi

add_keys
