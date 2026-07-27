{
  stdenv,
  fetchurl,
  autoPatchelfHook,
  binutils,
  custom,
}:

let
  info = custom.corp-pkgs-info.itsme-cli;
in
stdenv.mkDerivation {
  name = "itsme-cli";
  src = fetchurl {
    inherit (info) url;
    hash = info.hash_unencrypted;
  };

  dontUnpack = true;
  nativeBuildInputs = [
    autoPatchelfHook
    binutils
  ];

  buildPhase = ''
    ar x $src
    tar xvf data.tar.gz
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv usr/bin/itsme-cli $out/bin
  '';

  meta = {
    inherit (info) description homepage;
    platforms = [ "x86_64-linux" ];
    mainProgram = "splitty";
  };
}
