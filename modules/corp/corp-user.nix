# Corp-specific home configuration, active only for the "corp" userkind.
# `lib.mkIf` (rather than `lib.optionalAttrs`) keeps the module's attribute
# structure static, which is required now that the condition itself comes
# from the `local.user` option.
{
  # The corp shell tokens are sourced by the wrapped fish, guarded by the
  # runtime $USERKIND (the wrapper serves all userkinds).
  flake.wrappers.fish =
    { pkgs, lib, ... }:
    let
      fishlib = import ../shell/_fish/lib.nix;
    in
    {
      plugins = [
        (fishlib.mkSnippet pkgs "40-corp-tokens" ''
          if test "$USERKIND" = corp
            source "$(${lib.getExe pkgs.custom.sops-cached} ${pkgs.locallib.secrets + /corp/tokens.sh.sops})"
          end
        '')
      ];
    };

  flake.modules.homeManager.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = lib.mkIf (config.local.user.userkind == "corp") {
        home = {
          sessionVariables = {
            # CURL_CA_BUNDLE mess up with curl, blocking other non-copr requests.
            # CURL_CA_BUNDLE = "${config.xdg.dataHome}/ca-certificates/YandexInternalRootCA.crt";
            NODE_EXTRA_CA_CERTS = "${config.xdg.dataHome}/ca-certificates/YandexInternalRootCA.crt";
            NSS_DEFAULT_SSL_DIR = "${config.xdg.dataHome}/ca-certificates/";
          };

          file = {
            ".itsme/allCAs.pem".source = pkgs.locallib.secrets + /corp/allCAs.pem;
          };
        };

        xdg = {
          dataFile = {
            "ca-certificates/YandexInternalRootCA.crt".source =
              pkgs.locallib.secrets + /corp/YandexInternalRootCA.crt;
          };
        };

        local = {
          secrets.links =
            let
              home = config.home.homeDirectory;
            in
            {
              "${home}/.itsme/config.yaml".source = pkgs.locallib.secrets + /corp/config.yaml.sops;
              "${home}/.itsme/initial_ovpn.conf".source = pkgs.locallib.secrets + /corp/initial_ovpn.conf.sops;
              "${home}/.itsme/openvpn.conf".source = pkgs.locallib.secrets + /corp/openvpn.conf.sops;
              "${home}/.itsme/pins.txt".source = pkgs.locallib.secrets + /corp/pins.txt.sops;
              "${home}/.itsme/rudenkornk.pem".source = pkgs.locallib.secrets + /corp/rudenkornk.pem.sops;
              "${home}/.itsme/tls.key".source = pkgs.locallib.secrets + /corp/tls.key.sops;
            };
        };
      };
    };
}
