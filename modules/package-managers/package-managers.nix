{
  flake.modules.homeManager.base = { pkgs, ... }:
  # Package managers.
  {
    home.packages = with pkgs; [
      uv
      vcpkg
      yarn
    ];
  };
}
