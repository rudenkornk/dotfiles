{ pkgs, ... }:

# Other useful tools.
{
  home = {
    packages = with pkgs; [
      asciinema
      dos2unix
      hyperfine
      openldap
      stress
      stress-ng
      wiki-tui
      xh
    ];
  };

  programs = {
    tealdeer = {
      enable = true;
      settings.updates.auto_update = true;
    };

    fish = {
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
      };
    };
  };
}
