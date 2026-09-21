{ pkgs, ... }:

# Virtualization & containerization tools.
{
  home = {
    packages = with pkgs; [
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

    shellAliases = {
      d = "docker";
      p = "podman";
    };
  };

  programs.docker-cli = {
    enable = true;
    settings = {
      detachKeys = "ctrl-z";
    };
  };
}
