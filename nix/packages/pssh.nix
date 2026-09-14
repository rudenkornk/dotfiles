{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  pcsclite,
  systemdLibs,
  corp,
}:

let
  info = corp.pkgs-info.pssh;
in
stdenv.mkDerivation {
  pname = "pssh";
  inherit (info) version;

  src = fetchurl {
    inherit (info) url;
    hash = info.hash_unencrypted;
  };

  dontUnpack = true;

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    pcsclite
    systemdLibs
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/pssh
    runHook postInstall
  '';

  meta = {
    inherit (info) description homepage;
    # license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "pssh";
  };
}
