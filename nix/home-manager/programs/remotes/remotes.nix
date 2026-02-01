{ pkgs, ... }:

# Remote desktop, corporate tooling & VPNs.
{
  home.packages = with pkgs; [
    coder
    openconnect
    openldap
    openssh
    openvpn
    throne
  ];

  home = {
    file = {
      ".ssh" = {
        source = pkgs.locallib.secrets + /ssh;
        recursive = true;
      };
    };
  };

  programs.fish = {
    functions = {
      ldaps = {
        # It would be nice to use `builtins.readFile (pkgs.replaceVars ...)` here,
        # but it causes errors during `nix flake check --no-build` in a fresh environment,
        # since `builtins.readFile` expects a valid existing path, which is not yet ready at
        # evaluation time:
        # "error: path '/nix/store/...-ldaps.fish.drv' is not valid"
        body =
          with pkgs;
          lib.replaceStrings
            [ "@corp_auth@" "@jq@" "@sops-cached@" "@openldap@" ]
            [ "${pkgs.locallib.secrets + /corp_auth.sops.json}" "${jq}" "${sops-cached}" "${openldap}" ]
            (builtins.readFile ./fish/functions/ldaps.fish);
        wraps = "ldapsearch";
      };
      openconnect_corp = {
        body =
          with pkgs;
          lib.replaceStrings
            [ "@corp_auth@" "@jq@" "@sops-cached@" "@openconnect@" ]
            [ "${pkgs.locallib.secrets + /corp_auth.sops.json}" "${jq}" "${sops-cached}" "${openconnect}" ]
            (builtins.readFile ./fish/functions/openconnect_corp.fish);
        wraps = "openconnect";
      };
      Throne = {
        body =
          with pkgs;
          lib.replaceStrings [ "@throne@" ] [ "${throne}" ] (builtins.readFile ./fish/functions/Throne.fish);
        wraps = "Throne";
      };
    };
  };
}
