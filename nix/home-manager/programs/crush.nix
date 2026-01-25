{ pkgs, config, ... }:

{
  home = {
    packages = with pkgs; [
      (locallib.with_secrets {
        pkg = nur.repos.charmbracelet.crush;
        binary = "crush";
      })
    ];

    file = {
      "${config.xdg.configHome}/crush/crush.json".source = ./crush/crush.json;
    };
  };
}
