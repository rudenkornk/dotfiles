{ pkgs, ... }:

# Trust & encryption tools.
{
  home.packages = with pkgs; [
    age
    age-plugin-tpm
    cacert
    gnupg
    gpgme
    sops
    tpm2-tools
  ];
}
