{ pkgs, inputs, ... }:

{
  programs.fish = {
    enable = true;

    functions = {
      fish_greeting = {
        body = "";
      };
      fish_remove_path = {
        body = builtins.readFile ./fish/functions/fish_remove_path.fish;
        description = "Shows user added PATH entries and removes the selected one";
      };
    };
    interactiveShellInit = ''
      source ${./fish/conf.d/fzf.fish}
      source ${./fish/conf.d/python.fish}
      source ${./fish/conf.d/shell_utils.fish}
      source ${./fish/conf.d/ssh_client.fish}
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
      {
        name = "fzf";
        src = pkgs.applyPatches {
          inherit (fzf-fish) src;
          patches = [ ./fish/fzf.fish.patch ];
        };
      }
    ];
  };
}
