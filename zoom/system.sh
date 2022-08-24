#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
  zoom \

