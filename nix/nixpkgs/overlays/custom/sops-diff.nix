final: _prev:

final.writeShellApplication {
  name = "sops-diff";
  runtimeInputs = [
    final.coreutils
    final.custom.rvim
    final.git
    final.sops
  ];
  text = builtins.readFile ./scripts/sops-diff.sh;
}
