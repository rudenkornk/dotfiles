#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs &> rustup.rs
chmod +x rustup.rs
./rustup.rs -y
rm rustup.rs

