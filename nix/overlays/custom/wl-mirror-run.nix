final: _prev:

final.writeShellApplication {
  name = "wl-mirror-run";
  runtimeInputs = [
    final.jq
    final.niri
    final.wl-mirror
  ];
  text = builtins.readFile ./scripts/wl-mirror-run.sh;
}
