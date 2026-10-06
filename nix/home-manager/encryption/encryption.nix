{ pkgs, ... }:

# Trust & encryption tools.
{
  home.packages = with pkgs; [
    age
    age-plugin-tpm
    cacert
    gnupg
    gnutls
    gpgme
    libp11
    opensc
    openssl
    sops
    tpm2-pkcs11
    tpm2-tools
    tpm2-tss
    yubico-piv-tool
    yubikey-manager

    vim # rvim with custom hardening inside.
    custom.sops-diff
  ];

  systemd.user.services.preload-bash-secrets = pkgs.locallib.preload-bash-secrets;

  home = {
    sessionVariables = {
      SOPS_EDITOR = "rvim";
    };
  };

}
