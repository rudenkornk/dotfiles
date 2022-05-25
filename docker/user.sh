#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

mkdir ~/.docker
cat "$REPO_PATH/docker/docker_config.json" >> "~/.docker/config.json" # Do not create symbolic because it might be populated with docker credentials

newgrp docker
