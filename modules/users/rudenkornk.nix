{ config, ... }:
let
  flakeCfg = config;
in
{
  flake = {
    meta.users.rudenkornk = {
      username = "rudenkornk";
      name = "Nikita Rudenko";
      description = "Nikita Rudenko";
      email = "rudenkornk@gmail.com";
      userkind = "default";
      profile_image = ./_rudenkornk/profile.jpg;
    };

    modules.homeManager.user-rudenkornk = {
      imports = [ flakeCfg.flake.modules.homeManager.base ];
      local.user = flakeCfg.flake.meta.users.rudenkornk;
    };
  };
}
