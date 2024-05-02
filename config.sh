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
  sudo --user "$REMOTE_USER" \
    bash -c " \
    sudo bash -c '' && \
    PATH=$PATH \
    VIRTUAL_ENV=$VIRTUAL_ENV \
    ansible-playbook --extra-vars \"hosts_var=$HOSTS\" \
    --user \"$REMOTE_USER\" \
    --inventory \"$PROJECT_DIR/inventory.yaml\" \"$PROJECT_DIR/playbook.yaml\" \
    "
else
  ansible-playbook --extra-vars "hosts_var=$HOSTS" \
    --user "$REMOTE_USER" \
    --inventory "$PROJECT_DIR/inventory.yaml" "$PROJECT_DIR/playbook.yaml"
fi
