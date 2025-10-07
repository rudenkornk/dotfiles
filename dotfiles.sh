#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

root=$(dirname "$0")

ansible_distribution=$(grep -oP '^ID=\K.*' /etc/os-release | sed -e 's/\(.*\)/\L\1/' | sed 's/\([[:alpha:]]\)/\U\1/')
ansible_architecture=$(uname -m)

deb_arch=""
case $ansible_architecture in
x86_64) deb_arch="amd64" ;;
aarch64) deb_arch="arm64" ;;
*) deb_arch="$(dpkg --print-architecture)" ;;
esac

HOME=${HOME:-$(eval echo ~"$(whoami)")}
LOCAL_HOME=${LOCAL_HOME:-$HOME/.local}
CARGO_HOME=${CARGO_HOME:-$HOME/.cargo}
export PATH="$PATH":"$LOCAL_HOME/bin":"$CARGO_HOME/bin"

_apt_updated=""

function install_pkg() {
  local cmd="$1"
  local fedora_packages=${2:-$cmd}
  local ubuntu_packages=${3:-$fedora_packages}

  if ! command -v "$cmd" &>/dev/null; then
    sudo=sudo
    if [[ "$fedora_packages" == "sudo" ]]; then
      sudo=""
    fi

    # shellcheck disable=SC2086  # prevent word splitting.
    # Here it is intentional to pass several packages in one argument.
    if [[ $ansible_distribution == Ubuntu ]]; then
      if [[ "$_apt_updated" == "" ]]; then
        $sudo apt-get update
        _apt_updated=1
      fi
      $sudo apt-get install --yes --no-install-recommends $ubuntu_packages
    elif [[ $ansible_distribution == Fedora ]]; then
      $sudo dnf install --assumeyes $fedora_packages
    fi
  fi
}

function install_binary() {
  local cmd="$1"
  local extra_opts=${2:-$cmd}

  if ! command -v "$cmd" &>/dev/null; then
    url=$(grep -oP "https://.*$cmd.*" "$root/roles/manifest/vars/main.yaml")
    url=${url//"{{ deb_arch }}"/$deb_arch}
    url=${url//"{{ ansible_architecture }}"/$ansible_architecture}
    mkdir -p "$LOCAL_HOME/bin"

    if [[ "$url" == *".gz" || "$url" == *".xz" || "$url" == *".zip" || "$url" == *".tar" ]]; then
      # shellcheck disable=SC2086  # prevent word splitting, intentionally passing several options.
      curl -L "$url" |
        bsdtar --extract --verbose \
          --exclude=LICENSE* \
          --exclude=*.md \
          --exclude=*.txt \
          --exclude=doc \
          --cd "$LOCAL_HOME/bin" \
          $extra_opts
    else
      curl -L "$url" --output "$LOCAL_HOME/bin/$cmd"
    fi

    chmod +x "$LOCAL_HOME/bin/$cmd"
  fi
}

# sudo is required for all of the other package management operations.
# This is basically a dummy check, since the only way to install sudo without sudo is to being root.
install_pkg sudo
install_pkg curl "curl ca-certificates" # curl is required for uv installation.
if ! command -v uv &>/dev/null; then    # uv is required for python and dependency management.
  curl -LsSf https://astral.sh/uv/0.7.12/install.sh | sh
fi

# Dependencies after this point are optional and required for:
# - Configuring another host.
# - Formatting and linting.
# - Updating dependencies.

install_pkg bsdtar bsdtar libarchive-tools # bsdtar is required for installing other optional dependencies.

# Dependencies for configuring another host.
install_pkg rsync   # rsync is required for Ansible synchronization tasks.
install_pkg age     # age & sops is required for secrets decryption.
install_binary sops # age & sops is required for secrets decryption.
install_pkg podman  # podman is required for local configuration testing inside containers.

# Lint dependencies
install_pkg git                                  # git is required for secrets linting.
install_binary gitleaks                          # gitleaks is required for secrets linting.
install_binary typos                             # typos is required for generic typo linting.
install_binary shfmt                             # .sh code formatting.
install_binary shellcheck '--strip-components=1' # .sh code linting.

# Format dependencies.
install_binary stylua
install_pkg npm

# Generating roles dependency graph.
install_pkg dot graphviz

uv run dotfiles "${@:---help}"
