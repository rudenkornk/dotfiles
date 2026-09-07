{ pkgs, host, ... }:

{
  home = {
    packages = with pkgs; [
      exiftool
      gpu-screen-recorder
      shotcut # typos: ignore
    ];
  };

  programs = {
    obs-studio = {
      enable = true;

      package = pkgs.obs-studio.override { cudaSupport = host.gpu.cudaSupport or false; };

      plugins = with pkgs.obs-studio-plugins; [
        obs-backgroundremoval
        obs-gstreamer
        obs-pipewire-audio-capture
        obs-vaapi # AMD hardware acceleration.
        obs-vkcapture
        wlrobs
      ];
    };
  };
}
