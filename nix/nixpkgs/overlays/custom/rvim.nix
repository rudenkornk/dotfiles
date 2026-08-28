final: _prev:

final.lib.hiPrio (
  final.writeShellApplication {
    name = "rvim";
    runtimeInputs = [
      final.util-linux
      final.vim
    ];
    text = builtins.readFile ./scripts/rvim.sh;
  }
)
