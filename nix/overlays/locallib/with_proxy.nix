{ pkgs, ... }:

args: pkgs.locallib._with_secrets (args // { secretsScript = pkgs.locallib.bash_proxy; })
