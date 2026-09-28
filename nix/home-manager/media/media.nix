{ pkgs, host, ... }:

{
  home = {
    packages = with pkgs; [
      exiftool
      gpu-screen-recorder
      pdfarranger
      shotcut # typos: ignore
      (whisper-ctranslate2.override {
        python3Packages = python313Packages.overrideScope (
          _: prev: {
            ctranslate2 = prev.ctranslate2.override {
              ctranslate2-cpp = ctranslate2.override { withCUDA = host.gpu.cudaSupport or false; };
            };
          }
        );
      })
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
