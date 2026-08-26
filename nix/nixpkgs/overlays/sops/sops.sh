# shellcheck shell=bash

export SOPS_EDITOR="rvim"
export EDITOR="$SOPS_EDITOR"

exec sops "$@"
