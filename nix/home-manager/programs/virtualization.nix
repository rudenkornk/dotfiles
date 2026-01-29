{ pkgs, get_modules, ... }:

# Virtualization & containerization tools.
{
  home.packages = with pkgs; [
    docker
    docker-compose
    docker-machine-kvm2 # Required for `minikube --driver kvm2`, see https://github.com/kubernetes/minikube/issues/6023#issuecomment-2103782263
    kubectl
    kubernetes
    minikube
    podman
    qemu_full
  ];

  home.shellAliases = {
    d = "docker";
    p = "podman";
  };

  imports = get_modules ./virtualization;
}
