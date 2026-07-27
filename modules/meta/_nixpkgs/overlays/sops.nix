_: final: prev: {
  sops =
    # Wrapper over sops enforcing a safe, network-isolated editor via $SOPS_EDITOR.
    final.writeShellApplication {
      name = "sops";
      runtimeInputs = [
        prev.sops
        prev.util-linux
        prev.vim
      ];
      text = builtins.readFile ./sops/sops.sh;
    };
}
