#!/usr/bin/env bash
sleep "$2"

exec bash "$(dirname -- "${BASH_SOURCE[0]}")/task-status.sh" running "$1"
