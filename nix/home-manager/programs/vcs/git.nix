{
  pkgs,
  config,
  user,
  ...
}:

{
  home = {
    packages = with pkgs; [
      gh
      git
      git-lfs
    ];
    shellAliases = {
      g = "git";
    };

    file = pkgs.locallib.homefiles {
      inherit (config) xdg;
      path = ./configs;
    };
  };

  xdg = {
    configFile = {
      "git/user.ini".text = # ini
        ''
          [user]
            name = "${user.name}"
            email = "${user.email}"
        '';
    };
  };
}
