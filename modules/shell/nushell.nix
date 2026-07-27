{
  flake.modules.homeManager.base = { pkgs, lib, ... }: {
    programs.nushell = {
      enable = true;
    };
  };
}
