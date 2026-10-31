final: prev: {
  # TODO: remove this after 26.11 release
  xray = prev.xray.overrideAttrs (_old: rec {
    version = "26.10.29";
    src = final.fetchFromGitHub {
      owner = "XTLS";
      repo = "Xray-core";
      rev = "v${version}";
      hash = "sha256-GvEmwgAFcVDi7Nt7jSoEj/39A9qZQexkqF02/3hHY9o=";
    };
    vendorHash = "sha256-/WIfkQfxSV1ZcC6ATkIq2nNoIrlAy9dRiK8v/J0kd2M=";
  });
}
