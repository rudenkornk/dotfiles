{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeBinaryWrapper,
  zstd,
  custom,
}:

let
  info = custom.corp-pkgs-info.splitty;
in
stdenv.mkDerivation {
  pname = "splitty";
  inherit (info) version;

  src = fetchurl {
    inherit (info) url;
    hash = info.hash_unencrypted;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeBinaryWrapper
    zstd
  ];

  buildInputs = [ stdenv.cc.cc.lib ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/libexec
    zstd -d $src -o $out/libexec/.splitty-wrapped
    chmod +x $out/libexec/.splitty-wrapped
  '';

  postFixup = ''
    makeWrapper $out/libexec/.splitty-wrapped $out/bin/splitty
  '';

  meta = {
    inherit (info) description homepage;
    platforms = [ "x86_64-linux" ];
    mainProgram = "splitty";
  };
}
