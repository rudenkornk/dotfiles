{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeBinaryWrapper,
  fuse,
  custom,
}:

let
  info = custom.corp-pkgs-info.arc;
in
stdenv.mkDerivation {
  pname = "arc";
  inherit (info) version;

  src = fetchurl {
    inherit (info) url;
    hash = info.hash_unencrypted;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeBinaryWrapper
  ];

  buildInputs = [ stdenv.cc.cc.lib ];

  # The URL has no file extension, so `fetchurl` cannot detect the archive type on its own.
  # `src` is a plain gzip tarball with a single `arc` binary inside, no top-level directory to strip.
  unpackPhase = ''
    tar xzf $src
  '';

  installPhase = ''
    mkdir -p $out/libexec
    cp arc $out/libexec/.arc-wrapped
  '';

  postFixup = ''
    # `arc mount` shells out to bare `fusermount`, which must be the setuid-root wrapper
    # (NixOS provides one at `/run/wrappers/bin/fusermount`) to be able to perform the mount syscall.
    # Use `--suffix` rather than `--prefix` so that wrapper takes precedence over the plain,
    # non-setuid `fusermount` from this `fuse` package, which is kept only as a fallback.
    makeWrapper $out/libexec/.arc-wrapped $out/bin/arc \
      --suffix PATH : ${lib.makeBinPath [ fuse ]}
  '';

  meta = {
    description = "Arc — Yandex Arcadia monorepo VCS client.";
    homepage = "https://habr.com/ru/companies/yandex/articles/482926/";
    # license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "arc";
  };
}
