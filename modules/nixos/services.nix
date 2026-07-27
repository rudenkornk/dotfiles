{
  flake.modules.nixos.base = {
    services = {
      power-profiles-daemon = {
        enable = true;
      };

      upower = {
        enable = true;
      };

      # Firmware updates.
      fwupd = {
        enable = true;
      };

      pcscd = {
        enable = true;
      };
    };
  };
}
