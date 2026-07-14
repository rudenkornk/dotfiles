{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeBinaryWrapper,
  libcap_ng,
  lz4,
  lzo,
  openssl,
  pam,
  pkcs11helper,
  tpm2-abrmd,
}:

stdenv.mkDerivation {
  pname = "openvpn-ya";
  version = "2.6.12-ya";

  src = fetchurl {
    url = "https://download.yandex.ru/hd/vpn/openvpn_2.6.12-ya_22.04_amd64.deb";
    hash = "sha256-+r6huL1stdZMov+yOAAABmOgQMgyPhCpsr4eFtos/Lw=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeBinaryWrapper
  ];

  buildInputs = [
    libcap_ng
    lz4
    lzo
    openssl
    pam
    pkcs11helper
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir -p $out/libexec $out/bin $out/lib/openvpn-ya/plugins
    cp usr/sbin/openvpn $out/libexec/.openvpn-ya-wrapped
    cp usr/lib/x86_64-linux-gnu/openvpn/plugins/*.so $out/lib/openvpn-ya/plugins/

    mkdir -p $out/share/man/man5
    cp usr/share/man/man5/openvpn-examples.5.gz $out/share/man/man5/openvpn-ya-examples.5.gz

    mkdir -p $out/share/man/man8
    cp usr/share/man/man8/openvpn.8.gz $out/share/man/man8/openvpn-ya.8.gz
  '';

  postFixup = ''
    makeWrapper $out/libexec/.openvpn-ya-wrapped $out/bin/openvpn-ya \
      --prefix LD_LIBRARY_PATH : $out/lib/openvpn-ya \
      --prefix LD_LIBRARY_PATH : ${tpm2-abrmd}/lib
  '';

  meta = {
    description = "Yandex-customized OpenVPN binary.";
    homepage = "https://yandex.ru";
    # license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "openvpn-ya";
  };
}
