# Plain data about hosts and users, shared by every configuration class.
# Feature modules read these instead of receiving values through `specialArgs`.
{ lib, ... }: {
  options.flake.meta = {
    hosts = lib.mkOption {
      type = lib.types.attrsOf lib.types.raw;
      default = { };
      description = "Per-host metadata: name, RAM, disk device, monitors, GPU capabilities.";
    };

    users = lib.mkOption {
      type = lib.types.attrsOf lib.types.raw;
      default = { };
      description = "Per-user metadata: username, full name, email, userkind, profile image.";
    };
  };
}
