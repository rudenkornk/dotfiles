{ pkgs, get_modules, ... }:

{
  imports = get_modules ./programs;
}
