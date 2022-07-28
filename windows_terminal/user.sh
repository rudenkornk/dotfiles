#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

luarocks install --local luafilesystem
luarocks install --server=http://rocks.moonscript.org/manifests/amrhassan --local json4Lua

