{
  flake.modules.homeManager.base = { pkgs, config, ... }: {
    home = {
      packages = with pkgs; [
        git
        git-lfs
        gh
      ];
      shellAliases = {
        g = "git";
        a = "arc";
      };

      file = pkgs.locallib.homefiles {
        inherit (config) xdg;
        path = ./_configs;
      };
    };

    xdg = {
      configFile = {
        "git/user.ini".text = # ini
          ''
            [user]
              name = "${config.local.user.name}"
              email = "${config.local.user.email}"
          '';
      };
    };
  };
}
