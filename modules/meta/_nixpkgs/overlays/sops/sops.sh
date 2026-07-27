# shellcheck shell=bash

export SOPS_EDITOR="unshare --net --map-root-user vim -Z -u DEFAULTS -i NONE -n"
export EDITOR="$SOPS_EDITOR"

exec sops "$@"
