{
  user,
  lib,
  config,
  pkgs,
  ...
}:

{
  home = lib.optionalAttrs (user.userkind == "corp") {
    packages = with pkgs; [
      corp.ldaps
      corp.openconnect-run
      corp.openvpn-run
    ];

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

  xdg = lib.optionalAttrs (user.userkind == "corp") {
    configFile = {
      # `ai.nix` installs the default opencode config unconditionally.
      # Disable it here so the encrypted corp config from `local.secrets.links` owns this path.
      "opencode/opencode.jsonc".enable = false;
    };

    dataFile = {
      "ca-certificates/YandexInternalRootCA.crt".source =
        pkgs.locallib.secrets + /corp/YandexInternalRootCA.crt;
    };
  };

  programs = lib.optionalAttrs (user.userkind == "corp") {
    fish = {
      interactiveShellInit =
        # fish
        ''
          source "$(${pkgs.lib.getExe pkgs.custom.sops-cached} ${
            pkgs.locallib.secrets + /corp/tokens.sh.sops
          })"
        '';
    };
  };

  local = lib.optionalAttrs (user.userkind == "corp") {
    secrets.links =
      let
        home = config.home.homeDirectory;
      in
      {
        "${home}/.ssh/corp/config".source = pkgs.locallib.secrets + /corp/ssh_config.sops;

        "${config.xdg.dataHome}/opencode/auth.json".source =
          pkgs.locallib.secrets + /corp/opencode.auth.json.sops;
        "${config.xdg.configHome}/opencode/opencode.jsonc".source =
          pkgs.locallib.secrets + /corp/opencode.jsonc.sops;

        "${home}/.itsme/config.yaml".source = pkgs.locallib.secrets + /corp/config.yaml.sops;
        "${home}/.itsme/initial_ovpn.conf".source = pkgs.locallib.secrets + /corp/initial_ovpn.conf.sops;
        "${home}/.itsme/openvpn.conf".source = pkgs.locallib.secrets + /corp/openvpn.conf.sops;
        "${home}/.itsme/pins.txt".source = pkgs.locallib.secrets + /corp/pins.txt.sops;
        "${home}/.itsme/rudenkornk.pem".source = pkgs.locallib.secrets + /corp/rudenkornk.pem.sops;
        "${home}/.itsme/tls.key".source = pkgs.locallib.secrets + /corp/tls.key.sops;
      };
  };
}
