final: _prev:

final.writeShellApplication {
  name = "service-secrets";
  runtimeInputs = [ final.systemd ];
  text = builtins.readFile ./scripts/service-secrets.sh;
}
