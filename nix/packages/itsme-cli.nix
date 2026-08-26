{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeBinaryWrapper,
  tpm2-pkcs11,
  tpm2-tools,
  corp,
}:

let
  info = corp.pkgs-info.itsme-cli;
in
stdenv.mkDerivation {
  pname = "itsme-cli";
  inherit (info) version;

  src = fetchurl {
    inherit (info) url curlOptsList;
    hash = info.hash_unencrypted;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeBinaryWrapper
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 usr/bin/itsme-cli $out/bin/itsme-cli
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/itsme-cli \
      --set SSL_CERT_FILE /etc/ssl/certs/ca-bundle.crt \
      --prefix PATH : ${
        lib.makeBinPath [
          tpm2-pkcs11
          tpm2-tools
        ]
      }
  '';

  meta = {
    inherit (info) description homepage;
    platforms = [ "x86_64-linux" ];
    mainProgram = "itsme-cli";
  };
}
