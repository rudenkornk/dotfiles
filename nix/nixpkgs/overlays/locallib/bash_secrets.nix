{ pkgs, ... }:

''
  if [[ "$USERKIND" == "default" ]]; then
    # shellcheck source=/dev/null
    source "$(${pkgs.sops-cached}/bin/sops-cached ${pkgs.locallib.secrets + /proxy.sh.sops})"
    # shellcheck source=/dev/null
    source "$(${pkgs.sops-cached}/bin/sops-cached ${pkgs.locallib.secrets + /keys.sh.sops})"
  elif [[ "$USERKIND" == "corp" ]]; then
    # shellcheck source=/dev/null
    source "$(${pkgs.sops-cached}/bin/sops-cached ${pkgs.locallib.secrets + /corp_keys.sh.sops})"
  fi
''
