#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
  bash-completion \
  ca-certificates \
  curl \
  dos2unix \
  lsb-release \
  make \
  moreutils `# for ifne tool` \
  openssh-client \
  python3-pip \
  tar gzip zip unzip bzip2 \
  vim \
  wget \
  xsel `# for tmux-yank` \

