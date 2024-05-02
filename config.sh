#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

# Script parameters
# HOSTS
# IMAGE
# REMOTE_USER

PROJECT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

if [[ "$HOSTS" =~ localhost || "$HOSTS" =~ 127.0.0.1 ]]; then
  LOCAL=true
else
  LOCAL=false
fi

if [[ $LOCAL == true ]]; then
  # In case of local execution, privileges escalation is equvalent of calling sudo
  # We must call it beforehand, so Ansible will not ask for password
  sudo bash -c ''
fi

if [[ "$HOSTS" =~ ^dotfiles_ ]]; then
  ansible-playbook --extra-vars "container=$HOSTS image=$IMAGE" \
    --inventory "$PROJECT_DIR/inventory.yaml" "$PROJECT_DIR/playbook_dotfiles_container.yaml"
fi

ansible-playbook --extra-vars "hosts_var=$HOSTS" \
  --extra-vars "user=$REMOTE_USER" \
  --inventory "$PROJECT_DIR/inventory.yaml" "$PROJECT_DIR/playbook_bootstrap_hosts.yaml"

ansible-playbook --extra-vars "hosts_var=$HOSTS" \
  --user "$REMOTE_USER" \
  --inventory "$PROJECT_DIR/inventory.yaml" "$PROJECT_DIR/playbook.yaml"
