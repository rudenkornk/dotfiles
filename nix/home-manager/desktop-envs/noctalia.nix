{
  config,
  lib,
  pkgs,
  host,
  ...
}:

{
  home.packages = [ pkgs.noctalia ];

  systemd.user.services.noctalia = {
    Unit = {
      Description = "Noctalia desktop shell";
      Wants = [ "decrypt-noctalia.service" ];
      After = [ "niri.service" ];
      PartOf = [ "niri.service" ];
    };
    Install.WantedBy = [ "niri.service" ];
    Service = {
      ExecStart = lib.getExe pkgs.noctalia;
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  xdg = {
    configFile = {
      "noctalia/host.toml".source = host.noctalia;
    };
  };

  local.secrets = {
    file = {
      "${config.xdg.configHome}/noctalia/secrets.toml" = {
        source = pkgs.locallib.secrets + /noctalia.toml.sops;
        fallback = "";
        service-name = "decrypt-noctalia";
        before = [ "noctalia.service" ];
      };
      "${config.xdg.configHome}/noctalia/storage-key" = {
        source = pkgs.locallib.secrets + /noctalia-storage-key.sops;
        fallback = "";
        service-name = "decrypt-noctalia";
        before = [ "noctalia.service" ];
      };
    };
  };
}
