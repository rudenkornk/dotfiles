final: _prev:

final.writeShellApplication {
  name = "tmux-russian-keymaps";
  runtimeInputs = [
    final.python313
    final.tmux
  ];
  text = ''
    exec python3 ${./scripts/tmux-russian-keymaps.py} "$@"
  '';
}
