#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

mkdir --parents ~/.docker

config=~/.docker/config.json
if [[ ! -f $config || ! -s $config ]]; then
  echo "{}" > $config
fi

# Do not create symbolic because it might be populated with docker credentials
jq -s '.[0] * .[1]' "$SELF_PATH/config.json" "$config" | sponge $config

mkdir --parents ~/.config/fish/completions
wget https://raw.githubusercontent.com/docker/cli/master/contrib/completion/fish/docker.fish
mv docker.fish ~/.config/fish/completions

# TODO
#sudo usermod -aG docker $USER
#newgrp docker
