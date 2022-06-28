#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

mkdir --parents ~/.docker

config=~/.docker/config.json
if [[ ! -f $config ]]; then
  echo "{}" > $config
fi
# Do not create symbolic because it might be populated with docker credentials
cat $config | jq '.detachKeys="ctrl-z"' | sponge $config

newgrp docker
