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

  home = {
    shellAliases = {
      rvim =
        # Disable network.
        "unshare --net "
        +
          # Prevent 'Operation not permitted' error.
          # Appears as pseudo-root in environment.
          # https://unix.stackexchange.com/a/370484/500020
          "--map-root-user "
        + "vim "
        +
          # Restricted mode.
          "-Z "
        +
          # Disable all config files.
          "-u DEFAULTS "
        +
          # Disable history (`:help shada`).
          "-i NONE "
        +
          # Disable swap files.
          "-n";
    };

    sessionVariables = {
      SOPS_EDITOR = "unshare --net --map-root-user vim -Z -u DEFAULTS -i NONE -n";
    };
  };
}
