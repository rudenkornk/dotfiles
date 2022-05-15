#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

mkdir --parents ~/.local/bin

#ln --symbolic "$REPO_PATH/bash/inputrc" ~/.inputrc # vi mode in bash
cat "$REPO_PATH/bash/bashrc" >> ~/.bashrc

newgrp docker

