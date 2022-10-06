#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
  acpi \
  apt-transport-https \
  bison \
  build-essential \
  ca-certificates \
  curl \
  dos2unix \
  gnupg \
  gpg-agent \
  htop \
  iptables \
  iputils-ping \
  jq \
  lftp \
  libevent-dev \
  linux-tools-common \
  locales \
  lsb-release \
  ncurses-dev \
  net-tools \
  openssh-client \
  openssh-server \
  pkg-config \
  snap \
  software-properties-common \
  sshpass \
  tar gzip zip unzip bzip2 p7zip-full p7zip-rar \
  tcl \
  wget \

locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

