_: final: prev: {
  sops =
    # Wrapper over sops enforcing a safe, network-isolated editor via $SOPS_EDITOR.
    final.writeShellApplication {
      name = "sops";
      runtimeInputs = [
        prev.sops
        final.custom.rvim
      ];
      text = ''
        export SOPS_EDITOR="rvim"
        export EDITOR="$SOPS_EDITOR"

        exec sops "$@"
      '';
    };
}
