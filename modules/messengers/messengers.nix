{
  flake.modules.homeManager.base = { pkgs, config, ... }: {
    home = {
      packages = with pkgs; [ telegram-desktop ];

      file = pkgs.locallib.homefiles {
        inherit (config) xdg;
        path = ./_configs;
      };
    };

  };
}
