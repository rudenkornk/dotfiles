# shellcheck shell=bash
# Manages ssh-agent lifecycle and loads sops-encrypted SSH keys.
# Credits: https://gist.github.com/gerbsen/5fd8aa0fde87ac7a2cae

SSH_SOCK="${1:-${HOME}/.ssh/agent.sock}"

add_keys() {
  local keys=("$HOME"/.ssh/*.sops)
  for key in "${keys[@]}"; do
    sops --decrypt "$key" 2>/dev/null | ssh-add - 2>/dev/null ||
      echo "Failed to load/decrypt key: $(basename "$key")"
  done
}

ssh-add -l &>/dev/null
agent_status=$?
if [[ "$agent_status" -eq 2 ]]; then
  echo "Initializing new SSH agent ..."
  rm -f "$SSH_SOCK"
  ssh-agent -a "$SSH_SOCK" &>/dev/null
  add_keys
elif [[ "$agent_status" -eq 1 ]]; then
  add_keys
fi
