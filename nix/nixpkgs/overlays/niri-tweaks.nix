{ inputs, ... }:
final: prev: {
  niri-tweaks = final.stdenv.mkDerivation {
    pname = "niri-tweaks";
    version = "0-unstable-2026-03-19";
    src = inputs.niri-tweaks;

    nativeBuildInputs = [ final.makeWrapper ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/share/niri-tweaks
      for f in *.py; do
        cp "$f" "$out/share/niri-tweaks/"
        name=$(basename "$f" .py)
        makeWrapper ${final.python3}/bin/python3 "$out/bin/$name" \
          --add-flags "$out/share/niri-tweaks/$f"
      done
      for f in *.sh; do
        install -Dm755 "$f" "$out/bin/$(basename "$f" .sh)"
      done
      runHook postInstall
    '';
  };
}
