#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

ansible_distribution=$(grep -oP '^ID=\K.*' /etc/os-release | sed -e 's/\(.*\)/\L\1/' | sed 's/\([[:alpha:]]\)/\U\1/')
root=$(dirname "$0")

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

# curl is required for uv installation
if ! command -v curl &>/dev/null; then
  if [[ $ansible_distribution == Ubuntu ]]; then
    sudo apt-get update
    sudo apt-get install --yes --no-install-recommends curl ca-certificates
  elif [[ $ansible_distribution == Fedora ]]; then
    sudo dnf install --assumeyes curl ca-certificates
  fi
fi

# uv is required for python and dependency management
if ! command -v uv &>/dev/null; then
  HOME=${HOME:-$(eval echo ~"$(whoami)")}
  CARGO_HOME=${CARGO_HOME:-$HOME/.cargo}
  export PATH="$PATH":"$CARGO_HOME/bin"
  if ! command -v uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/0.3.0/install.sh | sh
  fi
fi

# rsync is required for Ansible synchronization tasks
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

uv run "$root/scripts/main.py" -- "${@:---help}"
