{
  flake.modules.homeManager.base = { pkgs, ... }:
  # Basic tools.
  {
    home.packages = with pkgs; [
      curl
      moreutils
      patch
      uutils-coreutils-noprefix
      vim
      wget
    ];
  };
}
