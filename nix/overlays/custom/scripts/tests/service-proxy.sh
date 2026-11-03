# shellcheck shell=bash

set -euo pipefail

temporary=$(mktemp -d "${TMPDIR:-/tmp/opencode}/service-proxy-test.XXXXXX")
trap 'command rm -rf -- "$temporary"' EXIT
export TEST_ROOT="$temporary"
export TEST_LOG="$temporary/commands"
export TEST_LOADER="$temporary/loader"
export XDG_RUNTIME_DIR="$temporary/user"
mkdir -p "$XDG_RUNTIME_DIR"

sed "s/@bashSecrets@/source \"\$TEST_LOADER\"/" \
  "$(dirname "$0")/../service-proxy.sh" >"$temporary/service-proxy"

sudo() {
  echo sudo >>"$TEST_LOG"
  "$@"
}
systemctl() {
  echo "systemctl $*" >>"$TEST_LOG"
  if [[ " $* " == *" show "* ]]; then
    echo "${TEST_LOAD_STATE:-loaded}"
  fi
}
install() {
  local -a arguments=()
  local argument
  for argument in "$@"; do
    arguments+=("${argument/#\/run\//$TEST_ROOT/system/}")
  done
  command install "${arguments[@]}"
}
rm() {
  local -a arguments=()
  local argument
  for argument in "$@"; do
    arguments+=("${argument/#\/run\//$TEST_ROOT/system/}")
  done
  command rm "${arguments[@]}"
}
export -f sudo systemctl install rm

cat >"$TEST_LOADER" <<'EOF'
[[ "$PROXY_APP" == "$TEST_APP" ]] || exit 1
[[ "$USERKIND" == corp ]] || exit 1
export HTTPS_PROXY='http://proxy/"$`\'
export no_proxy='localhost,example.org'
export PRIVATE_KEY=not-forwarded
EOF
export USERKIND=corp
export TEST_APP=dockerd
HTTP_PROXY=http://inherited bash -euo pipefail "$temporary/service-proxy" enable docker.service
environment="$temporary/system/service-proxy/docker.service.env"
grep -Fx 'HTTPS_PROXY="http://proxy/\"\$\`\\"' "$environment"
grep -Fx 'no_proxy="localhost,example.org"' "$environment"
if grep -Eq 'HTTP_PROXY=|PRIVATE_KEY=' "$environment"; then
  exit 1
fi
[[ $(stat -c %a "$environment") == 600 ]]
[[ $(stat -c %a "$(dirname "$environment")") == 700 ]]
grep -Fx 'systemctl try-restart docker.service' "$TEST_LOG"
grep -Fx 'EnvironmentFile="/run/service-proxy/docker.service.env"' \
  "$temporary/system/systemd/system/docker.service.d/90-service-proxy.conf"

export TEST_APP=podman
: >"$TEST_LOG"
bash -euo pipefail "$temporary/service-proxy" enable podman
[[ -f "$XDG_RUNTIME_DIR/service-proxy/podman.service.env" ]]
grep -Fx 'systemctl --user try-restart podman.service' "$TEST_LOG"
if grep -q sudo "$TEST_LOG"; then
  exit 1
fi

echo unrelated >"$XDG_RUNTIME_DIR/systemd/user/podman.service.d/other.conf"
bash -euo pipefail "$temporary/service-proxy" disable podman
[[ ! -f "$XDG_RUNTIME_DIR/service-proxy/podman.service.env" ]]
[[ ! -f "$XDG_RUNTIME_DIR/systemd/user/podman.service.d/90-service-proxy.conf" ]]
[[ -f "$XDG_RUNTIME_DIR/systemd/user/podman.service.d/other.conf" ]]

cp "$environment" "$temporary/original"
echo : >"$TEST_LOADER"
: >"$TEST_LOG"
bash -euo pipefail "$temporary/service-proxy" enable docker 2>"$temporary/warning"
grep -q Warning "$temporary/warning"
cmp "$environment" "$temporary/original"
if grep -Eq 'daemon-reload|try-restart' "$TEST_LOG"; then
  exit 1
fi

echo 'exit 1' >"$TEST_LOADER"
bash -euo pipefail "$temporary/service-proxy" enable docker 2>"$temporary/warning"
cmp "$environment" "$temporary/original"
if grep -Eq 'daemon-reload|try-restart' "$TEST_LOG"; then
  exit 1
fi

if TEST_LOAD_STATE=not-found bash -euo pipefail "$temporary/service-proxy" enable missing; then
  exit 1
fi
if bash -euo pipefail "$temporary/service-proxy" enable ../invalid; then
  exit 1
fi
bash -euo pipefail "$temporary/service-proxy" disable docker
[[ ! -f "$environment" ]]
echo 'service-proxy tests passed.'
