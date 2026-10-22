# shellcheck shell=bash

usage() {
  echo "Usage: service-secrets {without-all|without-keys|without-proxy|reset}"
  echo "Set secret loading for system Docker/Nix/Podman and user Podman until reset or reboot."
  echo "Restart active services only. Restarting Docker may disrupt containers."
  echo "This skips loading secrets; it does not clear inherited keys or proxy variables."
}

if [[ $# -eq 1 && ("$1" == "--help" || "$1" == "-h") ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

case "$1" in
without-all | without-keys | without-proxy)
  environment_args=(set-environment "WITHOUT_SECRETS=${1#without-}")
  ;;
reset)
  environment_args=(unset-environment WITHOUT_SECRETS)
  ;;
*)
  usage >&2
  exit 1
  ;;
esac

systemctl_bin=$(command -v systemctl)
sudo "$systemctl_bin" "${environment_args[@]}"
systemctl --user "${environment_args[@]}"

echo "Restarting active services; Docker containers may be disrupted."
sudo "$systemctl_bin" try-restart docker.service nix-daemon.service podman.service
systemctl --user try-restart podman.service
