{
  pkgs,
  config,
  user,
  ...
}:

{
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
