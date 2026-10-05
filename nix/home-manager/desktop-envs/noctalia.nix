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
    file = {
      "${config.xdg.configHome}/noctalia/secrets.toml" = {
        source = pkgs.locallib.secrets + /noctalia.toml.sops;
        fallback = "";
        before = [ "niri.service" ];
      };
      "${config.xdg.configHome}/noctalia/storage-key" = {
        source = pkgs.locallib.secrets + /noctalia-storage-key.sops;
        fallback = "";
        before = [ "niri.service" ];
      };
    };
  };
}
