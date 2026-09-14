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
      yandex-cloud
      corp.ldaps
      corp.openconnect-run
      corp.openvpn-run
    ];
    shellAliases = {
      a = "arc";
    };

    sessionVariables = {
      # CURL_CA_BUNDLE mess up with curl, blocking other non-copr requests.
      # CURL_CA_BUNDLE = "${config.xdg.dataHome}/ca-certificates/YandexInternalRootCA.crt";
      NODE_EXTRA_CA_CERTS = "${config.xdg.dataHome}/ca-certificates/YandexInternalRootCA.crt";
      NSS_DEFAULT_SSL_DIR = "${config.xdg.dataHome}/ca-certificates/";
    };
  };

  xdg = lib.optionalAttrs (user.userkind == "corp") {
    configFile = {
      # `local.merge-config` owns the corp target instead of the default Home Manager symlink.
      "opencode/opencode.jsonc".enable = false;
    };
    dataFile = {
      "ca-certificates/YandexInternalRootCA.crt".source =
        pkgs.locallib.secrets + /corp/YandexInternalRootCA.crt;
    };
  };

  programs = lib.optionalAttrs (user.userkind == "corp") {
    fish = {
      functions.g = {
        wraps = "git";
        body = builtins.readFile ./fish/functions/g.fish;
      };
      interactiveShellInit =
        # fish
        ''
          source ${config.xdg.configHome}/fish/functions/g.fish

          source "$(${pkgs.lib.getExe pkgs.custom.sops-cached} ${
            pkgs.locallib.secrets + /corp/tokens.sh.sops
          })"
        '';
    };
  };

  systemd.user.services = lib.optionalAttrs (user.userkind == "corp") {
    ssh-agent-corp-keys =
      let
        skottyConfig = pkgs.locallib.secrets + /corp/skotty.yaml.sops;
        corp_askpass = pkgs.writeShellApplication {
          name = "corp-yubikey-askpass";
          runtimeInputs = [
            pkgs.custom.sops-cached
            pkgs.yq-go
          ];
          text = lib.replaceStrings [ "@skotty_config@" ] [ "${skottyConfig}" ] (
            builtins.readFile ./scripts/ssh_askpass.sh
          );
        };
        client = pkgs.writeShellApplication {
          name = "ssh-client-corp";
          runtimeInputs = [
            corp_askpass
            pkgs.openssh
            pkgs.custom.sops-cached
            pkgs.yq-go
            pkgs.yubikey-manager
          ];
          text =
            lib.replaceStrings
              [ "@skotty_config@" "@pkcs11_provider@" ]
              [ "${skottyConfig}" "${pkgs.yubico-piv-tool}/lib/libykcs11.so" ]
              (builtins.readFile ./scripts/ssh_client.sh);
        };
      in
      {
        Unit = {
          Description = "Load SSH YubiKey keys into the OpenSSH agent";
          Requires = [ "ssh-agent-keys.service" ];
          After = [ "ssh-agent-keys.service" ];
        };
        Install.WantedBy = [ "default.target" ];
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "no";
          ExecStart = lib.getExe client;
        };
      };

    skotty =
      let
        skotty = "${config.home.homeDirectory}/.nix-profile/bin/skotty";
      in
      {
        Unit = {
          Wants = [ "dbus.socket" ];
          Requires = [ "merge-config.service" ];
          After = [
            "dbus.socket"
            "merge-config.service"
          ];
          Before = [ "graphical-session-pre.target" ];
          ConditionPathIsExecutable = skotty;
        };
        Install.WantedBy = [ "default.target" ];
        Service = {
          Type = "simple";
          # Do not restart on ordinary errors, which can include a rejected token PIN.
          Restart = "on-abnormal";
          RestartSec = 1;
          ExecStartPre = [
            "${pkgs.systemd}/bin/systemctl --user set-environment GSM_SKIP_SSH_AGENT_WORKAROUND=true"
            "${skotty} ssh export-env"
          ];
          ExecStart = "${skotty} start";
        };
      };
  };

  local = lib.optionalAttrs (user.userkind == "corp") {
    home.file = {
      ".".source = ./configs;
      ".itsme/allCAs.pem".source = pkgs.locallib.secrets + /corp/allCAs.pem;
    };

    merge-config.file = {
      "${config.xdg.configHome}/opencode/opencode.jsonc" = {
        mode = "dict";
        source = [
          ../ai/configs/.config/opencode/opencode.jsonc
          (pkgs.locallib.secrets + /corp/opencode.jsonc.sops)
        ];
        clearTarget = true;
        readOnlyTarget = true;
      };

      "${config.home.homeDirectory}/.codex/config.toml".source =
        pkgs.locallib.secrets + /corp/codex.config.toml.sops;

      "${config.home.homeDirectory}/.skotty/config.yaml" = {
        # After reinstall, run `skotty renew --fetch-only && skotty renew` to restore runtime state.
        mode = "dict";
        source = pkgs.locallib.secrets + /corp/skotty.yaml.sops;
      };
    };

    secrets.file =
      let
        home = config.home.homeDirectory;
      in
      {
        "${home}/.ssh/corp/config".source = pkgs.locallib.secrets + /corp/ssh_config.sops;
        "${home}/.ssh/corp/known_hosts".source = pkgs.locallib.secrets + /corp/ssh_known_hosts.sops;

        "${config.xdg.dataHome}/atuin/key".source = lib.mkForce (
          pkgs.locallib.secrets + /corp/atuin_key.sops
        );

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
