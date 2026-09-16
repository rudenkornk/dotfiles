final: prev:
let
  # NOTE: Bun 1.4 bundles opencode so that every prompt crashes, see https://github.com/anomalyco/opencode/issues/48876
  bun = prev.bun.overrideAttrs rec {
    version = "1.3.13";
    src = final.fetchurl {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64-baseline.zip";
      hash = "sha256-nYokKSpwaAkCBdqsCloiP19pc29Sh+N7+I07QDHtx1A=";
    };
  };
in
{
  opencode = (prev.opencode.override { inherit bun; }).overrideAttrs (
    _: prevAttrs: {
      patches = (prevAttrs.patches or [ ]) ++ [
        (final.locallib.patches + /opencode-1.18.29-thought-start-timestamp.patch)
      ];
    }
  );
}
