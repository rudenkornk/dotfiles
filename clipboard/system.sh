#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
IS_WSL=$(uname --all | grep --quiet WSL && echo true || echo false)
IS_DOCKER=$([[ -f /.dockerenv ]] && true || echo false) # make exception when running tests in docker

if [[ $IS_WSL == "true" && $IS_DOCKER == "false" ]]; then
  ln --symbolic --force "/mnt/c/Windows/System32/clip.exe" /usr/bin/clip.exe
  if ! win32yank.exe -o &> /dev/null; then
    win_userprofile=$(wslvar USERPROFILE)
    if [[ -z "$win_userprofile" ]]; then
      echo "ERROR: Looks like you are using WSL but wslvar does not work properly."
      echo "Maybe \$WSL_INTEROP socket is not set?"
      exit 1
    fi
    win_bin=$(wslpath "$win_userprofile")
    if [[ ! -f "$win_bin/AppData/Local/win32yank/win32yank.exe" ]]; then
      wget https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip --output-document win32yank.zip
      unzip win32yank.zip -d win32yank
      chmod +x win32yank/win32yank.exe
      mv --force win32yank "$win_bin/AppData/Local"
      rm win32yank.zip
      rm --recursive --force win32yank
    fi
    ln --symbolic --force "$win_bin/AppData/Local/win32yank/win32yank.exe" /usr/bin/win32yank.exe
  fi
else
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
    xsel
fi

