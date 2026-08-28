final: _prev:

# Simple wrapper over sops, which cache its output in tmpfs /run/user/$id/ dir.
# This is primarily needed to avoid multiple costly decryption queries when using TPM.

final.writeShellApplication {
  name = "sops-cached";
  runtimeInputs = [
    final.age
    final.age-plugin-tpm
    final.sops
    final.uutils-coreutils-noprefix
  ];
  text = builtins.readFile ./scripts/sops-cached.sh;
}
