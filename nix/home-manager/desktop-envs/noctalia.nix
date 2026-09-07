{
  config,
  pkgs,
  host,
  ...
}:

{
  home.packages = [ pkgs.noctalia ];

  xdg = {
    configFile = {
      "noctalia/host.toml".source = host.noctalia;
    };
  };

  local.secrets = {
    before = [ "niri.service" ];
    file = {
      "${config.xdg.configHome}/noctalia/secrets.toml" = {
        source = pkgs.locallib.secrets + /noctalia.toml.sops;
        fallback = "";
      };
      "${config.xdg.configHome}/noctalia/storage-key" = {
        source = pkgs.locallib.secrets + /noctalia-storage-key.sops;
        fallback = "";
      };
    };
  };
}
