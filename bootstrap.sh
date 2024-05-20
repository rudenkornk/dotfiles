#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

PROJECT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
ARTIFACTS_DIR=${ARTIFACTS_DIR:-$PROJECT_DIR/__artifacts__}

ansible_distribution=$(grep -oP '^ID=\K.*' /etc/os-release | sed -e 's/\(.*\)/\L\1/' | sed 's/\([[:alpha:]]\)/\U\1/')

# sudo is required for all of the other package management operations
# This is basically a dummy check, since the only way to install sudo without sudo
# is to being root
if ! command -v sudo &>/dev/null; then
  if [[ $ansible_distribution == Ubuntu ]]; then
    apt-get update
    apt-get install --yes --no-install-recommends sudo
  elif [[ $ansible_distribution == Fedora ]]; then
    dnf install --assumeyes sudo
  fi
fi

# tzdata is required for python3 installation on Ubuntu >= 23.10
if [[ $ansible_distribution == Ubuntu ]] && ! (dpkg --get-selections | grep --quiet tzdata); then
  sudo ln -fs /usr/share/zoneinfo/Europe/Moscow /etc/localtime
  sudo apt-get update
  sudo apt-get install --yes --no-install-recommends tzdata
fi

# python3 is required for Ansible, the main configuration tool in the project
if ! command -v python3 &>/dev/null; then
  if [[ $ansible_distribution == Ubuntu ]]; then
    sudo apt-get update
    sudo apt-get install --yes --no-install-recommends python3-venv python3-pip
  elif [[ $ansible_distribution == Fedora ]]; then
    sudo dnf install --assumeyes python3 python3-virtualenv python3-pip
  fi
fi

# hostname is required to regulate config artifacts if project locations is shared
if ! command -v hostname &>/dev/null; then
  if [[ $ansible_distribution == Ubuntu ]]; then
    sudo apt-get update
    sudo apt-get install --yes --no-install-recommends hostname
  elif [[ $ansible_distribution == Fedora ]]; then
    sudo dnf install --assumeyes hostname
  fi
fi

# make is responsible for most of the project targets, including Ansible calls
if ! command -v make &>/dev/null; then
  if [[ $ansible_distribution == Ubuntu ]]; then
    sudo apt-get update
    sudo apt-get install --yes --no-install-recommends make
  elif [[ $ansible_distribution == Fedora ]]; then
    sudo dnf install --assumeyes make
  fi
fi

# rsync is required for Ansibly synchronization tasks
if ! command -v rsync &>/dev/null; then
  if [[ $ansible_distribution == Ubuntu ]]; then
    sudo apt-get update
    sudo apt-get install --yes --no-install-recommends rsync
  elif [[ $ansible_distribution == Fedora ]]; then
    sudo dnf install --assumeyes rsync
  fi
fi

# podman is required for local configuration testing inside containers
if ! command -v podman &>/dev/null; then
  if [[ $ansible_distribution == Ubuntu ]]; then
    sudo apt-get update
    sudo apt-get install --yes --no-install-recommends podman
  elif [[ $ansible_distribution == Fedora ]]; then
    sudo dnf install --assumeyes podman
  fi
fi

# git is used for performing project dependencies updates
if ! command -v git &>/dev/null; then
  if [[ $ansible_distribution == Ubuntu ]]; then
    sudo apt-get update
    sudo apt-get install --yes --no-install-recommends git
  elif [[ $ansible_distribution == Fedora ]]; then
    sudo dnf install --assumeyes git
  fi
fi

# graphviz is used for generating Ansible roles dependency graph
if ! command -v dot &>/dev/null; then
  if [[ $ansible_distribution == Ubuntu ]]; then
    sudo apt-get update
    sudo apt-get install --yes --no-install-recommends graphviz
  elif [[ $ansible_distribution == Fedora ]]; then
    sudo dnf install --assumeyes graphviz
  fi
fi

VENV="$ARTIFACTS_DIR/$(hostname)/venv"

if [[ "$VENV" -ot "$PROJECT_DIR/requirements.txt" ]]; then
  python3 -m venv "$VENV"
  source "$VENV/bin/activate"
  pip3 install -r "$PROJECT_DIR/requirements.txt"
  touch "$VENV"
fi

source "$VENV/bin/activate"

mkdir -p "$ARTIFACTS_DIR/ansible_logs"

# Target is user-specific since Ansible collections are installed for a specific user by default
# In some cases we need to perform a bootstrap twice from different users.
# This tweak ensures that the collections are installed for the user who runs the bootstrap
collections_target="$ARTIFACTS_DIR/$(hostname)/ansible_collections_$(id --user --name)"
if [[ 
  ("$collections_target" -ot "$VENV") ||
  ("$collections_target" -ot "$PROJECT_DIR/playbook_ansible_collections.yaml") ||
  ("$collections_target" -ot "$PROJECT_DIR/roles/manifest/vars/ansible.yaml") ]] \
  ; then
  sudo bash -c ""
  ANSIBLE_LOG_PATH="$ARTIFACTS_DIR/ansible_logs/ansible_collections.log" \
    ansible-playbook --inventory inventory.yaml playbook_ansible_collections.yaml
  touch "$collections_target"
fi

final_target="$ARTIFACTS_DIR/$(hostname)/bootstrap_control_node_$(id --user --name)"
if [[ 
  ("$final_target" -ot "$collections_target") ||
  ("$final_target" -ot "${BASH_SOURCE[0]}") ]] \
  ; then
  touch "$final_target"
fi
