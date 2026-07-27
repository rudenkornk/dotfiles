{
  flake.modules.nixos.base = {
    services = {
      pulseaudio.enable = false;
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
    };

    # Enable sound with pipewire.
    security = {
      rtkit.enable = true;
    };
  };
}
