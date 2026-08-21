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
      # `local.merge-config` owns the corp target instead of the default Home Manager symlink.
      "${config.xdg.configHome}/opencode/opencode.jsonc".enable = false;
    };
  };

  xdg = lib.optionalAttrs (user.userkind == "corp") {
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
    merge-config.files = {
      "${config.xdg.configHome}/opencode/opencode.jsonc" = {
        source = [
          ./programs/ai/configs/.config/opencode/opencode.jsonc
          (pkgs.locallib.secrets + /corp/opencode.jsonc.sops)
        ];
        insertAfter = "INSERTION POINT";
        clearTarget = true;
        readOnlyTarget = true;
      };

      "${config.home.homeDirectory}/.codex/config.toml".source =
        pkgs.locallib.secrets + /corp/codex.config.toml.sops;
    };

    secrets.links =
      let
        home = config.home.homeDirectory;
      in
      {
        "${home}/.ssh/corp/config".source = pkgs.locallib.secrets + /corp/ssh_config.sops;

        "${home}/.claude/mcp-corp.json".source = pkgs.locallib.secrets + /corp/claude.mcp.json.sops;

        "${home}/.itsme/config.yaml".source = pkgs.locallib.secrets + /corp/config.yaml.sops;
        "${home}/.itsme/initial_ovpn.conf".source = pkgs.locallib.secrets + /corp/initial_ovpn.conf.sops;
        "${home}/.itsme/openvpn.conf".source = pkgs.locallib.secrets + /corp/openvpn.conf.sops;
        "${home}/.itsme/pins.txt".source = pkgs.locallib.secrets + /corp/pins.txt.sops;
        "${home}/.itsme/rudenkornk.pem".source = pkgs.locallib.secrets + /corp/rudenkornk.pem.sops;
        "${home}/.itsme/tls.key".source = pkgs.locallib.secrets + /corp/tls.key.sops;
      };
  };
}
