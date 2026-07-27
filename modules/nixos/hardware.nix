{
  flake.modules.nixos.base = { pkgs, ... }: {
    hardware = {
      bluetooth = {
        enable = true;
      };
      i2c = {
        enable = true;
      };

      firmware = [ pkgs.sof-firmware ];
    };
  };
}
