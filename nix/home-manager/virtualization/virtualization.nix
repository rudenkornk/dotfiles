{ config, pkgs, ... }:

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
      qemu_full
      vagrant

      (locallib.with_secrets { pkg = podman; })
      (wrapHelm kubernetes-helm {
        plugins = with kubernetes-helmPlugins; [
          helm-diff
          helm-mapkubeapis
          helm-secrets
          helm-unittest
        ];
      })
    ];

    shellAliases = {
      d = "docker";
      p = "podman";
    };

    sessionVariables = {
      DOCKER_CONFIG = "${config.xdg.configHome}/docker";
    };
  };

  local = {
    merge-config = {
      file = {
        # Allow docker to add creds to the file.
        "${config.xdg.configHome}/docker/config.json" = {
          mode = "dict";
          source = (pkgs.formats.json { }).generate "docker-config.json" { detachKeys = "ctrl-z"; };
        };
      };
    };
  };
}
