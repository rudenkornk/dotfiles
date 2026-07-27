{
  flake.modules.nixos.base = {
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;

        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
      };
      docker.enable = true;
      libvirtd.enable = true;
    };

    programs = {
      virt-manager.enable = true;
    };
  };
}
