final: _prev:

let
  python = final.python3.withPackages (ps: [
    ps.lark
    ps.ruamel-yaml
    ps.tomlkit
    ps.typer
  ]);
in
final.stdenvNoCC.mkDerivation {
  pname = "merge-config";
  version = "2.2.0";

  src = ./scripts/merge-config;

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ final.makeWrapper ];
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/libexec/merge-config
    cp merge-config.py $out/libexec/merge-config/merge-config
    cp jsonc.py $out/libexec/merge-config/
    makeWrapper ${python}/bin/python3 $out/bin/merge-config \
      --add-flags $out/libexec/merge-config/merge-config \
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
    description = "Merge managed dictionaries or text blocks into mutable configuration files";
    license = final.lib.licenses.mit;
    mainProgram = "merge-config";
    platforms = final.lib.platforms.linux;
  };
}
