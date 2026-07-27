{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  custom,
}:

let
  info = custom.corp-pkgs-info.skotty;
in
stdenv.mkDerivation {
  pname = "skotty";
  inherit (info) version;

  src = fetchurl {
    inherit (info) url curlOptsList;
    hash = info.hash_unencrypted;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];

  buildInputs = [ stdenv.cc.cc.lib ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/doc/skotty $out/share/skotty/icons
    cp usr/bin/skotty $out/bin/skotty
    cp usr/share/doc/yandex-skotty/changelog.gz $out/share/doc/skotty/
    cp usr/share/skotty/icons/* $out/share/skotty/icons/
  '';

  meta = {
    # license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "skotty";
  };
}
