final: _prev:

final.writeShellApplication {
  name = "service-proxy";
  runtimeInputs = [
    final.coreutils
    final.systemd
  ];
  text = builtins.replaceStrings [ "@bashSecrets@" ] [ final.locallib.bash_secrets ] (
    builtins.readFile ./scripts/service-proxy.sh
  );
}
