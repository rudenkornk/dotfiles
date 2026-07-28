# Wrapper-module fragment: source sops-encrypted API keys and proxy settings at
# program launch, dispatched on the runtime $USERKIND.
# Successor of the former `locallib.with_secrets` / `locallib.bash_secrets`.
# Sourcing soft-fails, so wrapped tools still start via `nix run` on machines
# without the age key (without the secret environment, of course).
{ pkgs, lib, ... }:
let
  sops-cached = lib.getExe pkgs.custom.sops-cached;
  src = file: ''. "$(${sops-cached} ${pkgs.locallib.secrets + file})" 2>/dev/null || true'';
in
{
  envDefault.USERKIND = "default";
  runShell = [
    {
      name = "secret-env";
      data = ''
        if [ "''${USERKIND:-}" = "corp" ]; then
          ${src /keys.sh.sops}
          ${src /proxy.sh.sops}
          ${src /corp/keys.sh.sops}
          ${src /corp/proxy.sh.sops}
        else
          ${src /keys.sh.sops}
          ${src /proxy.sh.sops}
        fi
      '';
    }
  ];
}
