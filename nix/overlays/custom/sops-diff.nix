final: _prev:

final.writeShellApplication {
  name = "sops-diff";
  runtimeInputs = [
    final.coreutils
    final.git
    final.sops
    final.vim
  ];
  text = builtins.readFile ./scripts/sops-diff.sh;
}
