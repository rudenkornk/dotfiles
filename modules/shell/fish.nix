{
  flake.modules.homeManager.base = { pkgs, ... }: {
    programs.fish = {
      enable = true;

      functions = {
        fish_greeting = {
          body = "";
        };
        fish_remove_path = {
          body = builtins.readFile ./_fish/functions/fish_remove_path.fish;
          description = "Shows user added PATH entries and removes the selected one";
        };
      };
      interactiveShellInit = ''
        source ${./_fish/conf.d/shell_utils.fish}
      '';
      plugins = with pkgs.fishPlugins; [
        {
          name = "autopair";
          inherit (autopair) src;
        }
        {
          name = "puffer";
          inherit (puffer) src;
        }
      ];
    };
  };
}
