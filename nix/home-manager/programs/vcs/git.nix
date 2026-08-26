{
  pkgs,
  config,
  user,
  ...
}:

let
  # Using explicit binary instead of a shellAliases to allow
  # `g` to be overridable with direnv.
  g = pkgs.runCommand "git-alias" { } ''
    mkdir -p "$out/bin"
    ln -s ${pkgs.lib.getExe pkgs.git} "$out/bin/g"
  '';
in
{
  home = {
    packages = with pkgs; [
      g
      gh
      git
      git-lfs
    ];

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
