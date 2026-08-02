{ pkgs, ... }:

{
  # Security spyware for corporate machine.
  # Here are several ways to check `osquery` health locally:
  # 1. Show logs from the service itself.
  #    Only works if `--verbose` flag is set!
  #    ```bash
  #    journalctl -u osqueryd.service -f
  #    ```
  #
  # 2. Show sent bytes to the remote server (must be increasing value):
  #    ```bash
  #    watch -n 5 'systemctl show osqueryd -p IPEgressBytes'
  #    ```
  #
  # 3. Show number of unsent entries from local monitoring database (should be low, <100):
  #    ```bash
  #    sudo sh -c '
  #      osqueryd=$(systemctl cat osqueryd | sed -n "s/^ExecStart=\([^ ]*\).*/\1/p")
  #      cp -a /var/lib/osquery/osquery.db /var/tmp/osq-copy.db
  #      "$osqueryd" --database_path /var/tmp/osq-copy.db --database_dump 2>/dev/null | grep -c "^logs\[tls_r_"
  #      rm -rf /var/tmp/osq-copy.db'
  #    ```
  services.osquery = {
    enable = true;
    flags = {
      # Main flags.
      # tls_hostname = <encrypted in EnvironmentFile>;
      fromenv = "tls_hostname";
      tls_server_certs = "${pkgs.locallib.secrets + /corp/allCAs.pem}";
      disable_audit = "false";
      disable_extensions = "true";
      host_identifier = "uuid";

      # Daemon control flags.
      force = "true";
      watchdog_level = "-0";
      watchdog_utilization_limit = "30";

      # Enrollment flags.
      enroll_tls_endpoint = "/api/v1/osquery/enroll";
      enroll_secret_path = "/run/user/0/secrets/osquery/enroll_secret";
      tls_enroll_max_attempts = "22";

      # Configuration control flags.
      config_plugin = "tls";
      config_refresh = "300";
      config_tls_endpoint = "/api/v1/osquery/config";
      config_enable_backup = "true";

      # Distributed query service flags.
      disable_distributed = "false";
      distributed_interval = "14";
      distributed_tls_read_endpoint = "/api/v1/osquery/distributed/read";
      distributed_tls_write_endpoint = "/api/v1/osquery/distributed/write";

      # Logging/results flags.
      logger_plugin = "tls,filesystem"; # Also save logs locally with `filesystem` plugin.
      logger_rotate = "true";
      # logger_path="/var/log/osquery"; # Already set to this path.
      logger_tls_endpoint = "/logger";
      logger_min_status = "10";
      logger_min_stderr = "10";
      stderrthreshold = "3";
      verbose = "true"; # See problematic tls issues locally.
    };
  };

  systemd.services.osqueryd = {
    serviceConfig = {
      EnvironmentFile = "/run/user/0/secrets/osquery/environment_file";
      ReadOnlyPaths = [ "/" ];
      ReadWritePaths = [
        "/var/lib/osquery"
        "/var/log/osquery"
        "/run"
      ];

      InaccessiblePaths = [
        "-/home/rudenkornk/.config/chromium/"
        "-/home/rudenkornk/.config/google-chrome/"
        "-/home/rudenkornk/.config/mozilla/"
        "-/home/rudenkornk/.config/sops/"
        "-/home/rudenkornk/.gnupg/"
        "-/home/rudenkornk/.local/share/keyrings/"
        "-/home/rudenkornk/.local/share/TelegramDesktop/"
        "-/home/rudenkornk/.pki/"

        "-/home/rudenkornk_corp/.config/chromium/"
        "-/home/rudenkornk_corp/.config/google-chrome/"
        "-/home/rudenkornk_corp/.config/mozilla/"
        "-/home/rudenkornk_corp/.config/sops/"
        "-/home/rudenkornk_corp/.gnupg/"
        "-/home/rudenkornk_corp/.local/share/keyrings/"
        "-/home/rudenkornk_corp/.local/share/TelegramDesktop/"
        "-/home/rudenkornk_corp/.pki/"

        "-/root/.config/sops/"
        # "-/run/user/0/secrets/"
        "-/run/user/1000/secrets/"
        "-/run/user/1001/secrets/"
      ];
    };
    unitConfig = {
      ConditionFileNotEmpty = [
        "/run/user/0/secrets/osquery/enroll_secret"
        "/run/user/0/secrets/osquery/environment_file"
      ];
    };
  };

  local = {
    secrets = {
      links = {
        "/run/user/0/secrets/osquery/enroll_secret".source =
          pkgs.locallib.secrets + /corp/osquery_enroll_secret.sops;
        "/run/user/0/secrets/osquery/environment_file".source =
          pkgs.locallib.secrets + /corp/osquery_environment_file.sops;
      };
      before = [ "osqueryd.service" ];
    };
  };
}
