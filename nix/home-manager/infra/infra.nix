{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ansible
    awscli2
    k9s
    kubectl
    kubernetes
    minikube
    molecule
    terraform

    (wrapHelm kubernetes-helm {
      plugins = with kubernetes-helmPlugins; [
        helm-diff
        helm-mapkubeapis
        helm-secrets
        helm-unittest
      ];
    })
  ];
}
