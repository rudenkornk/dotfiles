{
  stdenv,
  fetchurl,
  installShellFiles,
  corp,
}:

let
  info = corp.pkgs-info.ycp;
in
stdenv.mkDerivation {
  pname = "ycp";
  inherit (info) version;

  src = fetchurl {
    inherit (info) url;
    hash = info.hash_unencrypted;
  };

  dontUnpack = true;

  nativeBuildInputs = [ installShellFiles ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/ycp
    installShellCompletion --cmd ycp \
      --bash <($out/bin/ycp completion bash) \
      --zsh <($out/bin/ycp completion zsh)
    runHook postInstall
  '';

  meta = {
    inherit (info) description homepage;
    # license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ycp";
  };
}
