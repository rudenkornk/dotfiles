final: _prev:

final.writeShellApplication {
  name = "throne-run";
  runtimeInputs = [ final.throne ];
  text = builtins.readFile ./scripts/throne-run.sh;
}
