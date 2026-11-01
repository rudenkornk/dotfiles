final: _:

final.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "omo";
  version = "5.1.57";

  src = final.fetchurl {
    url = "https://github.com/code-yeongyu/oh-my-openagent/releases/download/v${finalAttrs.version}/omo-linux-x64-baseline";
    hash = "sha256-HV/3o0PvLAe4GCtxJi/2MGiicfTa/7e8On76ndQaopQ=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  nativeBuildInputs = with final; [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [ final.stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/omo"
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram "$out/bin/omo" \
      --prefix LD_LIBRARY_PATH : ${final.lib.makeLibraryPath [ final.stdenv.cc.cc.lib ]} \
      --set PI_SKIP_VERSION_CHECK 1
  '';

  nativeInstallCheckInputs = [ final.writableTmpDirAsHomeHook ];
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export PI_OFFLINE=1 PI_TELEMETRY=0
    "$out/bin/omo" --version
    "$out/bin/omo" --help > /dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Standalone OmO coding agent with the Senpi engine";
    homepage = "https://github.com/code-yeongyu/oh-my-openagent";
    # license = final.lib.licenses.unfree;
    sourceProvenance = [ final.lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "omo";
  };
})
