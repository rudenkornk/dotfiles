{ pkgs, user, ... }:

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
  };

  local = {
    home.file = {
      ".".source = ./configs;
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
