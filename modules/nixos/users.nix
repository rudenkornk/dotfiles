{ config, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.base = {
    users.users = builtins.mapAttrs (name: user: {
      isNormalUser = true;
      inherit (user) description;

      # Keeping initialPassword open in case anyone blindly tries this config.
      initialPassword = "123";
      extraGroups = [
        "docker"
        "i2c"
        "libvirtd"
        "networkmanager"
        "tss"
        "wheel"
        "wireshark"
      ];
    }) flakeCfg.flake.meta.users;
  };
}
