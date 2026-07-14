{
  lib,
  stdenv,
  fetchurl,
  makeBinaryWrapper,
  fuse,
  custom,
}:

let
  info = custom.corp-pkgs-info.ya;
in
stdenv.mkDerivation {
  pname = "ya";
  inherit (info) version;

  src = fetchurl {
    inherit (info) url;
    hash = info.hash_unencrypted;
  };

  nativeBuildInputs = [ makeBinaryWrapper ];

  # ya-bin is a statically linked binary — no `autoPatchelfHook` or `buildInputs` needed.
  # The URL has no file extension, so `fetchurl` cannot detect the archive type on its own.
  # `src` is a plain gzip tarball with a single `ya-bin` binary inside, no top-level directory to strip.
  unpackPhase = ''
    tar xzf $src
  '';

  installPhase = ''
    mkdir -p $out/libexec
    cp ya-bin $out/libexec/.ya-wrapped
  '';

  postFixup = ''
    # `ya` embeds Arc's VCS mount code and shells out to bare `fusermount`, which must be the
    # setuid-root wrapper that NixOS provides at `/run/wrappers/bin/fusermount`.
    # Use `--suffix` so that wrapper takes precedence over the plain, non-setuid `fusermount`
    # from this `fuse` package, which is kept only as a fallback.
    makeWrapper $out/libexec/.ya-wrapped $out/bin/ya \
      --suffix PATH : ${lib.makeBinPath [ fuse ]}
  '';

  meta = {
    description = "A cross-platform distribution, building, testing, and debugging toolkit focused on monorepositories.";
    homepage = "https://github.com/yandex/yatool";
    # license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ya";
  };
}
