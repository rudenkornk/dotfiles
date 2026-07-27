{ config, ... }:
let
  flakeCfg = config;
in
{
  flake = {
    meta.users.rudenkornk_corp = {
      username = "rudenkornk_corp";
      name = "Nikita Rudenko";
      description = "Nikita Rudenko (corp)";
      email = "rudenkornk@gmail.com";
      userkind = "corp";
      profile_image = ./_rudenkornk_corp/profile.jpg;
      extraEnv = {
        YA_USER = "rudenkornk";
      };
    };

    modules.homeManager.user-rudenkornk_corp = {
      imports = [ flakeCfg.flake.modules.homeManager.base ];
      local.user = flakeCfg.flake.meta.users.rudenkornk_corp;
    };
  };
}
