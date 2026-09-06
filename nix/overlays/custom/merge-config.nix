final: _prev:

let
  python = final.python3.withPackages (ps: [ ps.typer ]);
in
final.stdenvNoCC.mkDerivation {
  pname = "merge-config";
  version = "1.1.0";

  src = ./scripts/merge-config;

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ final.makeWrapper ];
  nativeCheckInputs = [ python ];
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    python3 test_merge_config.py
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    printf '#!${python}/bin/python3\n' > $out/bin/merge-config
    cat merge-config.py >> $out/bin/merge-config
    chmod 755 $out/bin/merge-config
    wrapProgram $out/bin/merge-config \
      --prefix PATH : ${final.lib.makeBinPath [ final.custom.sops-cached ]}
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/merge-config --help > /dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Merge managed JSON or text blocks into mutable configuration files";
    license = final.lib.licenses.mit;
    mainProgram = "merge-config";
    platforms = final.lib.platforms.linux;
  };
}
