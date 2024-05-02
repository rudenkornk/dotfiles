#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

# Script parameters
# HOSTS
# IMAGE
# BUILD_DIR
# REMOTE_USER

PROJECT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

if [[ "$HOSTS" =~ localhost || "$HOSTS" =~ 127.0.0.1 ]]; then
  LOCAL=true
else
  LOCAL=false
fi

logs_path="$(realpath "$BUILD_DIR")/ansible_logs"
mkdir -p "$logs_path"

if [[ $LOCAL == true ]]; then
  # In case of local execution, privileges escalation is equvalent of calling sudo
  # We must call it beforehand, so Ansible will not ask for password
  sudo bash -c ''
fi

if [[ "$VERIFY_UNCHANGED" == true ]]; then
  # Clear logs from previous runs
  rm "$logs_path"/*
fi

if [[ "$HOSTS" =~ ^dotfiles_ ]]; then
  ANSIBLE_LOG_PATH="$logs_path/container.log" \
    ansible-playbook --extra-vars "container=$HOSTS image=$IMAGE" \
    --inventory "$PROJECT_DIR/inventory.yaml" "$PROJECT_DIR/playbook_dotfiles_container.yaml"
fi

ANSIBLE_LOG_PATH="$logs_path/bootstrap_hosts.log" \
  ansible-playbook --extra-vars "hosts_var=$HOSTS" \
  --extra-vars "user=$REMOTE_USER" \
  --inventory "$PROJECT_DIR/inventory.yaml" "$PROJECT_DIR/playbook_bootstrap_hosts.yaml"

if [[ $LOCAL == true ]] && [[ "$REMOTE_USER" != $(id --user --name) ]]; then
  # A special case with local execution from a different user
  # In such case Ansible does not change any environment variables, including $HOME or $USER
  # Effectively Ansible executes playbook as a current user instead or $REMOTE_USER
  # Thus, we must manually change user beforehand with a sudo call
  #
  # This, however, introduces another problem:
  # After user change, privileges escalation from Ansible playbooks no longer works,
  # since we have opened another shell
  # To fix this, we have to call nested sudo alongside ansible call
  #
  # One more problem is that nested shell disguises parent's python virtual environment,
  # which results in picking wrong Ansible binary.
  # We have to set $PATH and $VIRTUAL_ENV manually back to their original values
  chmod 777 "$logs_path"
  sudo --user "$REMOTE_USER" \
    bash -c " \
    sudo bash -c '' && \
    PATH=$PATH \
    VIRTUAL_ENV=$VIRTUAL_ENV \
    ANSIBLE_LOG_PATH=\"$logs_path/main.log\" \
    ansible-playbook --extra-vars \"hosts_var=$HOSTS\" \
    --user \"$REMOTE_USER\" \
    --inventory \"$PROJECT_DIR/inventory.yaml\" \"$PROJECT_DIR/playbook.yaml\" \
    "
else
  ANSIBLE_LOG_PATH="$logs_path/main.log" \
    ansible-playbook --extra-vars "hosts_var=$HOSTS" \
    --user "$REMOTE_USER" \
    --inventory "$PROJECT_DIR/inventory.yaml" "$PROJECT_DIR/playbook.yaml"
fi

if [[ "$VERIFY_UNCHANGED" == true ]]; then
  for log in "$logs_path"/*; do
    if (grep -oP "changed=\d+" "$log" | grep -oPq "changed=[1-9]"); then
      echo "IDEMPOTENCY CHECK FAILED"
      exit 1
    fi
  done
fi
