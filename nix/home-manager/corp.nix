{
  user,
  lib,
  config,
  pkgs,
  ...
}:

{
  home = lib.optionalAttrs (user.userkind == "corp") {
    sessionVariables = {
      NODE_EXTRA_CA_CERTS = "${config.xdg.dataHome}/corp-certificates/YandexInternalRootCA.crt";
      NSS_DEFAULT_SSL_DIR = "${config.xdg.dataHome}/corp-certificates/";
    };

    file = {
      ".itsme/allCAs.pem".source = pkgs.locallib.secrets + /corp/allCAs.pem;
    };
  };

  xdg = lib.optionalAttrs (user.userkind == "corp") {
    dataFile = {
      "corp-certificates/YandexInternalRootCA.crt".source =
        pkgs.locallib.secrets + /corp/YandexInternalRootCA.crt;
    };
  };

  local = lib.optionalAttrs (user.userkind == "corp") {
    secrets.links =
      let
        home = config.home.homeDirectory;
      in
      {
        "${home}/.arc/token".source = pkgs.locallib.secrets + /corp/token.sops;
        "${home}/.mcp/token".source = pkgs.locallib.secrets + /corp/token.sops;
        "${home}/.ya_token".source = pkgs.locallib.secrets + /corp/token.sops;

        "${home}/.itsme/config.yaml".source = pkgs.locallib.secrets + /corp/config.yaml.sops;
        "${home}/.itsme/initial_ovpn.conf".source = pkgs.locallib.secrets + /corp/initial_ovpn.conf.sops;
        "${home}/.itsme/openvpn.conf".source = pkgs.locallib.secrets + /corp/openvpn.conf.sops;
        "${home}/.itsme/pins.txt".source = pkgs.locallib.secrets + /corp/pins.txt.sops;
        "${home}/.itsme/rudenkornk.pem".source = pkgs.locallib.secrets + /corp/rudenkornk.pem.sops;
        "${home}/.itsme/tls.key".source = pkgs.locallib.secrets + /corp/tls.key.sops;
      };
  };
}
