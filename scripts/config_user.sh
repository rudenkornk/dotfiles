#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

component="$1"

"$REPO_PATH/scripts/caption.sh" "CONFIGURING USER FOR ${component^^}";
"$REPO_PATH/$component/user.sh" ||
{ scripts/caption.sh "ERROR CONFIGURING USER FOR ${component^^}!"; exit 1; };

