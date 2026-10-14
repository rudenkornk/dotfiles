{ host, ... }:
final: prev:

# Setting `config.cudaSupport` for the entire package set is an alternative,
# but it triggers 24+ hours of compilation without extra benefits.
prev.lib.optionalAttrs (host.gpu.cudaSupport or false) {
  obs-studio = prev.obs-studio.override { cudaSupport = true; };
  whisper-ctranslate2 = prev.whisper-ctranslate2.override {
    python3Packages = prev.python3Packages.overrideScope (
      _: pythonPrev: {
        ctranslate2 = pythonPrev.ctranslate2.override {
          ctranslate2-cpp = prev.ctranslate2.override { withCUDA = true; };
        };
      }
    );
  };
}
