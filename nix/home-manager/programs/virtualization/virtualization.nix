{ pkgs, get_modules, ... }:

# Virtualization & containerization tools.
{
  home.packages = with pkgs; [
    docker
    docker-compose
    k9s
    kubectl
    kubernetes
    minikube
    podman
    qemu_full
    vagrant
  ];

  home.shellAliases = {
    d = "docker";
    p = "podman";
  };

  programs.docker-cli = {
    enable = true;
    settings = {
      detachKeys = "ctrl-z";
    };
  };
}
