{ pkgs, get_modules, ... }:

# VCS.
{
  imports = get_modules ./vcs;
}
