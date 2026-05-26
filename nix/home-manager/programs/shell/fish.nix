{ pkgs, ... }:

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
      source ${./fish/conf.d/shell_utils.fish}
      set -gx SSH_AUTH_SOCK $HOME/.ssh/agent.sock
      bash ${./scripts/ssh_client.sh} $SSH_AUTH_SOCK
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
}
