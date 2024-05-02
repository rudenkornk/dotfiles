#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

PROJECT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
BUILD_DIR=${BUILD_DIR:-$PROJECT_DIR/__build__}

if command -v apt-get &>/dev/null; then
  distro=ubuntu
  export DEBIAN_FRONTEND=noninteractive
elif command -v dnf &>/dev/null; then
  distro=fedora
else
  echo "Met unknown distro, supported Ubuntu and Fedora" >&2
  exit 1
fi

if ! command -v sudo &>/dev/null; then
  if [[ $distro == ubuntu ]]; then
    apt-get update
    apt-get install --yes --no-install-recommends sudo
  elif [[ $distro == fedora ]]; then
    dnf install --assumeyes sudo
  fi
fi

if [[ $distro == ubuntu ]] && ! (dpkg --get-selections | grep --quiet tzdata); then
  sudo ln -fs /usr/share/zoneinfo/Europe/Moscow /etc/localtime
  sudo apt-get update
  sudo apt-get install --yes --no-install-recommends tzdata
fi

if ! command -v python3 &>/dev/null; then
  if [[ $distro == ubuntu ]]; then
    sudo apt-get update
    sudo apt-get install --yes --no-install-recommends python3-venv python3-pip
  elif [[ $distro == fedora ]]; then
    sudo dnf install --assumeyes python3
  fi
fi

if ! command -v make &>/dev/null; then
  if [[ $distro == ubuntu ]]; then
    sudo apt-get update
    sudo apt-get install --yes --no-install-recommends make
  elif [[ $distro == fedora ]]; then
    sudo dnf install --assumeyes make
  fi
fi

if ! command -v git &>/dev/null; then
  if [[ $distro == ubuntu ]]; then
    sudo apt-get update
    sudo apt-get install --yes --no-install-recommends git
  elif [[ $distro == fedora ]]; then
    sudo dnf install --assumeyes git
  fi
fi

if [[ "$BUILD_DIR/venv" -ot "$PROJECT_DIR/requirements.txt" ]]; then
  python3 -m venv "$BUILD_DIR/venv"
  source "$BUILD_DIR/venv/bin/activate"
  pip3 install -r "$PROJECT_DIR/requirements.txt"
  touch "$BUILD_DIR/venv"
fi

source "$BUILD_DIR/venv/bin/activate"

export ANSIBLE_LOG_PATH="$BUILD_DIR/ansible_logs/bootstrap_control_node.log"

if [[ 
  ("$BUILD_DIR/bootstrap_control_node" -ot "$BUILD_DIR/venv") ||
  ("$BUILD_DIR/bootstrap_control_node" -ot "$PROJECT_DIR/playbook_bootstrap_control_node.yaml") ||
  ("$BUILD_DIR/bootstrap_control_node" -ot "$PROJECT_DIR/roles/manifest/vars/main.yaml") ]] \
  ; then
  sudo bash -c ""
  ansible-playbook --inventory inventory.yaml playbook_bootstrap_control_node.yaml
  touch "$BUILD_DIR/bootstrap_control_node"
fi
