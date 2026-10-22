{ pkgs, ... }:

let
  sops-cached = pkgs.lib.getExe pkgs.custom.sops-cached;
in
# bash
''
  if [[ -z "''${WITHOUT_SECRETS:-}" || "''${WITHOUT_SECRETS:-}" == "keys" ]]; then
    if [[ "$USERKIND" == "default" ]]; then
      # shellcheck source=/dev/null
      source "$(${sops-cached} ${pkgs.locallib.secrets + /proxy.sh.sops})"
    elif [[ "$USERKIND" == "corp" ]]; then
      # shellcheck source=/dev/null
      source "$(${sops-cached} ${pkgs.locallib.secrets + /proxy.sh.sops})"
      # shellcheck source=/dev/null
      source "$(${sops-cached} ${pkgs.locallib.secrets + /corp/proxy.sh.sops})"
    fi
  fi
''
