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

    custom.rvim
  ];

  home = {
    sessionVariables = {
      SOPS_EDITOR = "rvim";
    };
  };

}
