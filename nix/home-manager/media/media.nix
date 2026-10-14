{ pkgs, host, ... }:

{
  home = {
    packages = with pkgs; [
      exiftool
      gpu-screen-recorder
      pdfarranger
      shotcut # typos: ignore
      (
        if host.gpu.cudaSupport or false then
          whisper-ctranslate2
        else
          whisper-cpp.override { vulkanSupport = true; }
      )
    ];
  };

  programs = {
    obs-studio = {
      enable = true;

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
