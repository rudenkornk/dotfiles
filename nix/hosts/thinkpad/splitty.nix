# Split-DNS agent that routes some traffic through corp proxies.
#
# Two things this service cannot assume are present at start:
#
#   1. The binary. Its recipe (`nix/packages/splitty.nix`) reads encrypted `corp-pkgs-info`,
#      so it only builds from a working tree with decrypted secrets and is installed manually:
#      ```bash
#      sudo nix build --profile /nix/var/nix/profiles/splitty ~/projects/dotfiles#splitty
#      ```
#
#   2. The config. It carries internal endpoints, so it is committed encrypted and decrypted
#      into tmpfs at boot by the shared `local.secrets` mechanism, which symlinks it into place.
#
# Either being absent is diagnosed to the journal and retried: `Restart = "always"` below turns
# a non-zero exit into a retry loop that recovers once the binary is installed.
{ pkgs, ... }:

let
  # A dedicated system profile gives a stable root-controlled path and protects the binary from GC.
  # Per-user profiles are searched as a fallback, so a plain `nix profile add .#splitty` also works.
  system_profile = "/nix/var/nix/profiles/splitty";
  candidates = [
    "${system_profile}/bin/splitty"
    "/home/*/.nix-profile/bin/splitty"
  ];

  encrypted_config = pkgs.locallib.secrets + /corp/splitty_config.yaml.sops;
  # `local.secrets` decrypts the config into tmpfs and symlinks this path to the plaintext.
  config_file = "/run/user/0/secrets/splitty/config.yaml";
in
{
  # Decrypt the config at boot, ordered before this unit.
  local.secrets = {
    links.${config_file}.source = encrypted_config;
    before = [ "splitty.service" ];
  };

  # Splitty's Linux split-DNS backend works only through `systemd-resolved`,
  # so it must be enabled system-wide in configuration.nix.
  systemd.services.splitty = {
    description = "Corp Splitty";
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ encrypted_config ];

    # Diagnose the two "not ready yet" cases, then hand off to the daemon.
    # A non-zero exit here is caught by `Restart = "always"` and retried with backoff.
    script = ''
      if [[ ! -r ${config_file} ]]; then
        echo "${config_file} is missing: config was not decrypted, check decrypt-secrets.service." >&2
        exit 1
      fi
      # `sops-cached` writes this exact marker instead of content when decryption fails.
      read -r first_line <${config_file} || true
      if [[ "$first_line" == "# decryption failed" ]]; then
        echo "${config_file} failed to decrypt (TPM locked or secrets absent), check decrypt-secrets.service." >&2
        exit 1
      fi
      for candidate in ${toString candidates}; do
        if [[ -x "$candidate" ]]; then
          exec "$candidate" start --config ${config_file}
        fi
      done
      echo "splitty binary not found, checked: ${toString candidates}" >&2
      echo "Decrypt corp secrets, then run: sudo nix build --profile ${system_profile} <dotfiles>#splitty" >&2
      exit 1
    '';

    unitConfig = {
      # Never rate-limit start attempts: the binary may appear at any time after a manual install.
      StartLimitIntervalSec = 0;
    };

    serviceConfig = {
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";

      Restart = "always";
      # Upstream restarts instantly (`RestartSec=0`).
      # Grow the delay up to 5 minutes instead, so a missing binary does not produce a hot retry loop.
      RestartSec = 1;
      RestartSteps = 8;
      RestartMaxDelaySec = 300;

      TimeoutStartSec = 60;
      TimeoutStopSec = 60;

      # Memory locking is required for eBPF maps.
      LimitMEMLOCK = "infinity";
      MemoryAccounting = true;

      # `runtime_dir` (/var/run/splitty) and `cache_dir` (/var/cache/splitty) from the config;
      # systemd creates them before start.
      RuntimeDirectory = "splitty";
      CacheDirectory = "splitty";

      # No `CapabilityBoundingSet`: `CAP_SYS_ADMIN` is required and can regain the other caps,
      # so restricting them is upgrade-time upkeep without real confinement.

      # `/etc/hosts` is omitted from `ReadWritePaths` below: on NixOS it is a store symlink
      # and the `hosts` handler is disabled in the config.
      ProtectSystem = "strict";
      ReadWritePaths = [
        "/var/run"
        "/var/cache"
      ];
      NoNewPrivileges = true;
      KeyringMode = "private";
    };
  };
}
