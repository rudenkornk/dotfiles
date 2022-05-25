#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

wget https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
rm get-pip.py

# To uninstall pip
# python -m pip uninstall pip setuptools

