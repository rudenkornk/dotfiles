final: prev: {
  # TODO: remove this after 26.11 release
  xray = prev.xray.overrideAttrs (_old: rec {
    version = "26.10.31";
    src = final.fetchFromGitHub {
      owner = "XTLS";
      repo = "Xray-core";
      rev = "v${version}";
      hash = "sha256-wTKW8XUP/HXWI7e4jbBw3aGSPpPX7KjkxFwLMb9vxSA=";
    };
    vendorHash = "sha256-JLzEYsnhiATt1JpXD0SgFOhhHUFS34JIdBJXg4eAcL0=";
  });
}
