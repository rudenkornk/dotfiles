#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
  apt-transport-https \
  bison \
  build-essential \
  ca-certificates \
  curl \
  dos2unix \
  jq \
  libevent-dev \
  locales \
  lsb-release \
  ncurses-dev \
  openssh-client \
  pkg-config \
  software-properties-common \
  tar gzip zip unzip bzip2 \
  wget \

locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

