#!/usr/bin/env bash

set -x

REPO_PATH=$(realpath "$(dirname "$0")/..")
HAS_XSERVER=$([[ -d /usr/share/X11/ ]] && echo true || echo false)
IS_WSL=$(uname -a | grep --quiet WSL && echo true || echo false)
IS_WAYLAND=$(echo $XDG_SESSION_TYPE | grep --quiet wayland && echo true || echo false)
IS_SSH=$([[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]] && echo true || echo false)

if [[ -z "$PRIMARY_USER" ]]; then
  echo "Please set PRIMARY_USER var"
  exit 1
fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  bash-completion \
  ca-certificates \
  curl \
  docker.io \
  dos2unix \
  make \
  moreutils \
  openssh-client \
  python3-pip \
  tar gzip zip unzip bzip2 \
  vim \
  wget \
  xsel `# for tmux-yank`\

# Some special processing is needed for tmux-yank on wayland, see
# https://github.com/tmux-plugins/tmux-yank
if [[ $IS_WAYLAND == "true" ]]; then
  # TODO
  :
fi

if [[ $IS_XSERVER == "true" ]]; then
  ln -s "$REPO_PATH/keyboard_layouts/rnk" /usr/share/X11/xkb/symbols/rnk
  # Insert contents of evdev.xml into /usr/share/X11/xkb/rules/evdev.xml into appropriate place
  # sudo dpkg-reconfigure xkb-data
fi

WSL_CONF=/etc/wsl.conf
if [[ $IS_WSL == "true" && ((-f $WSL_CONF && ! -s $WSL_CONF) || ! -f $WSL_CONF) ]]; then
  ln --symbolic --force "$REPO_PATH/wsl.conf" $WSL_CONF
fi

usermod -aG docker $PRIMARY_USER

