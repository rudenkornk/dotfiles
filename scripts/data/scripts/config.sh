#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

# ARGS LIST:
#
# ANSIBLE_COLLECTIONS_PATH
# ANSIBLE_VERBOSITY
# CONFIG_MODE
# HOSTS
# INVENTORY
# LOCAL
# LOGS_PATH
# PLAYBOOK
# PLAYBOOK_BOOTSTRAP_HOSTS
# REMOTE_USER
# REPO_PATH

if [[ "$LOCAL" == true ]]; then
  # In case of local execution, privileges escalation is equvalent of calling sudo
  # We must call it beforehand, so Ansible will not ask for password
  sudo bash -c ''
fi

ANSIBLE_LOG_PATH="$LOGS_PATH/bootstrap_hosts.log" \
  ansible-playbook --extra-vars "hosts_var=$HOSTS" \
  --extra-vars "user=$REMOTE_USER" \
  --inventory "$INVENTORY" "$PLAYBOOK_BOOTSTRAP_HOSTS"

if [[ "$CONFIG_MODE" == bootstrap ]]; then
  exit
fi

if [[ "$CONFIG_MODE" == minimal ]]; then
  MINIMAL_MODE=true
  SERVER_MODE=false
elif [[ "$CONFIG_MODE" == server ]]; then
  MINIMAL_MODE=false
  SERVER_MODE=true
elif [[ "$CONFIG_MODE" == full ]]; then
  MINIMAL_MODE=false
  SERVER_MODE=false
else
  echo "Unknown CONFIG_MODE: $CONFIG_MODE"
  exit 1
fi

USER=$(id --user --name)

if [[ $LOCAL != true ]] || [[ "$REMOTE_USER" == "$USER" ]]; then
  ANSIBLE_LOG_PATH="$LOGS_PATH/main.log" \
    ansible-playbook \
    --extra-vars "hosts_var=$HOSTS" \
    --extra-vars "{ minimal_mode: $MINIMAL_MODE }" \
    --extra-vars "{ server_mode: $SERVER_MODE }" \
    --user "$REMOTE_USER" \
    --inventory "$INVENTORY" "$PLAYBOOK"
else
  # A special case with local execution from a different user
  # Unlike 'ssh connection', 'local connection' does not actually relogin and change environment
  # Which makes specifying different user for local connection impossible
  #
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
  #
  # Finally, we have to additionally pass ansible collections of the USER to the REMOTE_USER,
  # since they are installed on per-user basis by default

  yellow='\033[1;33m'
  color_end='\033[0m'
  echo -e "${yellow}[WARNING]: Requested to configure local machine for user $REMOTE_USER on behalf of $USER${color_end}"
  echo -e "${yellow}[WARNING]: The way Ansible 'local connection' works does not allow to perform such configuration straight away.${color_end}"
  echo -e "${yellow}[WARNING]: Because of this, we will run Ansible with 'sudo --user $REMOTE_USER'.${color_end}"
  echo -e "${yellow}[WARNING]: as well as providing limited access writes to $REMOTE_USER to some files in the current project.${color_end}"

  chmod a=u "$LOGS_PATH"
  chmod a=u "$LOGS_PATH/"*
  chmod a=u "$INVENTORY"

  sudo --user "$REMOTE_USER" \
    bash -c " \
        sudo bash -c '' && \
        export PATH=\"$PATH\" && \
        export ANSIBLE_COLLECTIONS_PATH=\"$ANSIBLE_COLLECTIONS_PATH\" && \
        export ANSIBLE_VERBOSITY=\"$ANSIBLE_VERBOSITY\" && \

        ANSIBLE_LOG_PATH=\"$LOGS_PATH/main.log\" \
        ansible-playbook \
        --extra-vars \"hosts_var=$HOSTS\" \
        --extra-vars \"{ minimal_mode: $MINIMAL_MODE }\" \
        --extra-vars \"{ server_mode: $SERVER_MODE }\" \
        --user \"$REMOTE_USER\" \
        --inventory \"$INVENTORY\" \"$PLAYBOOK\" \
      "
fi
