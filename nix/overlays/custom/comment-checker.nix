final: _:

# `oh-my-openagent` fetches this same release itself unless it finds the name on `PATH`.

final.stdenv.mkDerivation rec {
  pname = "comment-checker";
  version = "0.8.0";

  src = final.fetchurl {
    url =
      "https://github.com/code-yeongyu/go-claude-code-comment-checker/"
      + "releases/download/v${version}/comment-checker_v${version}_linux_amd64.tar.gz";
    hash = "sha256-D/Am/iRKoK+VZ9U7BGHJer9aUPhs4c61Ux/VQZSX3U8=";
  };

  nativeBuildInputs = [ final.autoPatchelfHook ];
  buildInputs = [ final.stdenv.cc.cc.lib ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 comment-checker $out/bin/comment-checker
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/comment-checker --help > /dev/null
  '';

  meta = {
    license = final.lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "comment-checker";
  };
}
