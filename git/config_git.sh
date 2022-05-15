#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

ln --symbolic "$REPO_PATH/git/gitconfig" ~/.gitconfig

# Hack for git on windows:
#git config --system core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe

