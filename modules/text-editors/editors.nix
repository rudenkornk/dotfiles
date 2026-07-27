{
  flake.modules.homeManager.base = { pkgs, config, ... }: {
    home = {
      packages = with pkgs; [ libreoffice ];
    };

  };
}
