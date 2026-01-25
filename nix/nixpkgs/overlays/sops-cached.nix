_: final: prev: {
  sops-cached =
    # Simple wrapper over sops, which cache its output in tmpfs /run/user/$id/ dir.
    # This is primarily needed to avoid multiple costly decryption queries when using TPM.

    final.writeShellApplication {
      name = "sops-cached";

      # Packages needed by your script (e.g., sops, jq, etc.)
      runtimeInputs = [
        final.sops
        final.uutils-coreutils-noprefix
      ];

      text = builtins.readFile ./sops-cached/sops-cached.sh;
    };
}
