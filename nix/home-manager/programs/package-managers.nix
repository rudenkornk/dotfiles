{ pkgs, ... }:

# Package managers.
{
  home.packages = with pkgs; [
    uv
    vcpkg
    yarn
  ];
}
