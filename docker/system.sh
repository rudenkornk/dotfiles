#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

if [[ -z "$PRIMARY_USER" ]]; then
  echo "Please set PRIMARY_USER var"
  exit 1
fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
  docker.io \

usermod -aG docker $PRIMARY_USER

