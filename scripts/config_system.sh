#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

component="$1"

"$REPO_PATH/scripts/caption.sh" "CONFIGURING SYSTEM FOR ${component^^}";
"$REPO_PATH/$component/system.sh" ||
{ scripts/caption.sh "ERROR CONFIGURING SYSTEM FOR ${component^^}!"; exit 1; };

